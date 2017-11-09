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
        albums_list.push(name: album['Name'],
                         id: album['AlbumKey'],
                         web_uri: album['WebUri'],
                         images_uri: album['Uris']['AlbumImages']['Uri'],
                         type: 'album')
      end
      break if (start + count) > resp['Pages']['Total'].to_i
      start += count
    end
    albums_list
  end

  def albums_long(path = '', node_id = @root_node)
    album_list = []
    node_children(node_id)['Node'].each do |node|
      node_path = File.join(path, node['Name'])
      puts node_path
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

  def folders
    folder_list = []
    resp = get('/api/v2/folder/user/bcaldwell!folderlist')
    resp['FolderList'].each do |folder|
      folder_list.push(name: folder['Name'],
                       web_uri: folder['UrlPath'],
                       uri: folder['Uri'],
                       type: 'folder')
    end
    folder_list
  end

  def http(method, url, headers = {}, _body = nil)
    headers['Accept'] = 'application/json'

    response = @http.request(method, url, headers)
    raise 'Request failed' unless response.is_a? Net::HTTPSuccess
    JSON.parse(response.body)['Response']
  end

  def get(url, params = nil, headers = {})
    uri = URI.parse(url)
    uri.query = URI.encode_www_form(params) if params
    http(:get, uri.to_s, headers)
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

  def upload_images(images, album_id, headers: {}, workers: 4)
    Parallel.each(images, in_processes: workers) do |image|
      upload(image, album_id, headers)
      puts "Done #{image}"
    end
  end

  private

  def get_access_token
    raise 'Not Implemented'
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
end
