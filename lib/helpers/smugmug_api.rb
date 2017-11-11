require 'helpers/secrets'
require 'oauth'
require 'uri'
require 'json'
require 'mimemagic'
require 'parallel'

class SmugmugAPI
  attr_accessor :http, :uploader
  OAUTH_ORIGIN = 'https://secure.smugmug.com'.freeze
  REQUEST_TOKEN_URL = '/services/oauth/1.0a/getRequestToken'.freeze
  ACCESS_TOKEN_URL = '/services/oauth/1.0a/getAccessToken'.freeze
  AUTHORIZE_URL = '/services/oauth/1.0a/authorize'.freeze
  API_ENDPOINT = 'https://api.smugmug.com'.freeze
  UPLOAD_ENDPOINT = 'http://upload.smugmug.com/'.freeze

  def initialize(ejson_file = '~/.photo_helper.ejson')
    ejson_file = File.expand_path(ejson_file)
    @secrets = Secrets.new(ejson_file, %i[api_key api_secret])
    get_access_token if !@secrets.access_token || !@secrets.access_secret

    @http = get_access_token
    @uploader = get_access_token(UPLOAD_ENDPOINT)
    user_resp = user
    @user = user_resp['NickName']
    @root_node = File.basename(user_resp['Uris']['Node']['Uri'])
  end

  def albums
    albums_list = []
    start = 1
    count = 100
    loop do
      resp = get("/api/v2/user/#{@user}!albums", start: start, count: count)

      resp['Album'].each do |album|
        albums_list.push(album_parser(album))
      end
      break if (start + count) > resp['Pages']['Total'].to_i
      start += count
    end
    albums_list
  end

  def albums_long(path = '', node_id = @root_node)
    album_list = []
    node_children(node_id)['Node'].each do |node|
      node_path = path.empty? ? node['Name'] : File.join(path, node['Name'])
      case node['Type']
      when 'Folder'
        album_list.concat(albums_long(node_path, node['NodeID']))
      when 'Album'
        album_list.push(path: node_path,
                        name: node['Name'],
                        web_uri: node['WebUri'],
                        node_uri: node['Uri'],
                        id: File.basename(node['Uris']['Album']['Uri']))
      end
    end
    album_list
  end

  def node_children(id)
    get("/api/v2/node/#{id}!children")
  end

  def user
    get('/api/v2!authuser')['User']
  end

  def images; end

  def folders
    folder_list = []
    resp = get('/api/v2/folder/user/bcaldwell!folderlist')
    resp['FolderList'].each do |folder|
      folder_list.push(name: folder['Name'],
                       url_name: folder['UrlName'],
                       web_uri: folder['UrlPath'],
                       uri: folder['Uri'],
                       albums_url: folder['Uris']['FolderAlbums']['Uri'],
                       type: 'folder')
    end
    folder_list
  end

  def get_or_create_album(path)
    folder_path = File.dirname(path).split('/').map(&:capitalize).join('/')
    album_name = File.basename(path).capitalize
    album = nil

    folder = get_or_create_folder(folder_path)
    resp = get(folder[:albums_url])
    albums = get(folder[:albums_url])['Album'] if resp.key? 'Album'
    albums ||= []
    albums.each do |album_raw|
      next unless album_raw['Name'] == album_name
      album = album_parser(album_raw)
    end

    if album.nil?
      url = "/api/v2/folder/user/#{@user}"
      url += "/#{folder_path}" unless folder_path.empty?
      url += '!albums'
      resp = post(url, Name: album_name.capitalize,
                       UrlName: album_name.tr(' ', '-').capitalize,
                       Privacy: 'Unlisted')
      album_raw = resp['Album']
      album = album_parser(album_raw)
    end
    album
  end

  def get_or_create_folder(path)
    parts = path.split('/')
    current_path = ''
    folder = nil

    parts.each do |part|
      part = part.capitalize
      new_path = current_path.empty? ? part : File.join(current_path, part)
      resp = http_raw(:get, "/api/v2/folder/user/#{@user}/#{new_path}")
      if resp.is_a? Net::HTTPSuccess
        folder_raw = JSON.parse(resp.body)['Response']['Folder']
        folder = folder_parser(folder_raw)
      else
        url = "/api/v2/folder/user/#{@user}"
        url += "/#{current_path}" unless current_path.empty?
        url += '!folders'
        resp = post(url, Name: part.capitalize,
                         UrlName: part.tr(' ', '-').capitalize,
                         Privacy: 'Unlisted')
        folder = folder_parser(resp['Folder'])
      end
      current_path = new_path
    end

    folder
  end

  def http(method, url, headers = {}, _body = nil)
    response = http_raw(method, url, headers, _body)
    raise 'Request failed' unless response.is_a? Net::HTTPSuccess
    JSON.parse(response.body)['Response']
  end

  def get(url, params = nil, headers = {})
    url.tr!(' ', '-')
    uri = URI.parse(url)
    uri.query = URI.encode_www_form(params) if params
    http(:get, uri.to_s, headers)
  end

  def post(url, body = {}, headers = {})
    url.tr!(' ', '-')
    headers['Accept'] = 'application/json'
    response = @http.post(url, body, headers)
    raise 'Request failed' unless response.is_a? Net::HTTPSuccess
    JSON.parse(response.body)['Response']
  end

  def upload(image_path, album_id, headers = {})
    image = File.open(image_path)

    headers.merge!('Content-Type' => MimeMagic.by_path(image_path).type,
                   'X-Smug-AlbumUri' => "/api/v2/album/#{album_id}",
                   'X-Smug-ResponseType' => 'JSON',
                   'X-Smug-Version' => 'v2',
                   'charset' => 'UTF-8',
                   'Accept' => 'JSON',
                   'X-Smug-FileName' => File.basename(image_path),
                   'Content-MD5' => Digest::MD5.file(image_path).hexdigest)

    resp = @uploader.post('/', image, headers)
    resp.body
  end

  def upload_images(images, album_id, headers = {}, workers: 4)
    counter = 0
    Parallel.each(images, in_threads: workers) do |image|
      # puts image
      upload(image, album_id, headers)
      counter += 1
      puts "#{counter}/#{images.count} Done #{image}"
    end
  end

  private

  def get_access_token
    raise 'Not Implemented'
  end

  def http_raw(method, url, headers = {}, _body = nil)
    url.tr!(' ', '-')
    headers['Accept'] = 'application/json'

    @http.request(method, url, headers)
  end

  def get_access_token(endpoint = API_ENDPOINT)
    @consumer = OAuth::Consumer.new(
      @secrets.api_key,
      @secrets.api_secret,
      site: endpoint
    )
    # # Create the access_token for all traffic
    OAuth::AccessToken.new(@consumer, @secrets.access_token, @secrets.access_secret)
  end

  def folder_parser(folder)
    {
      name: folder['Name'],
      url_name: folder['UrlName'],
      web_uri: folder['UrlPath'],
      uri: folder['Uri'],
      albums_url: folder['Uris']['FolderAlbums']['Uri'],
      type: 'folder'
    }
  end

  def album_parser(album)
    { name: album['Name'],
      id: album['AlbumKey'],
      web_uri: album['WebUri'],
      images_uri: album['Uris']['AlbumImages']['Uri'],
      type: 'album' }
  end
end
