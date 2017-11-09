require 'helpers/secrets'
require 'oauth'
require 'uri'
require 'json'
require 'mimemagic'
require 'parallel'

class Smugmug
  attr_accessor :http, :uploader
  OAUTH_ORIGIN = 'https://secure.smugmug.com'
  REQUEST_TOKEN_URL = '/services/oauth/1.0a/getRequestToken'
  ACCESS_TOKEN_URL = '/services/oauth/1.0a/getAccessToken'
  AUTHORIZE_URL = '/services/oauth/1.0a/authorize'
  API_ENDPOINT = 'https://api.smugmug.com'
  UPLOAD_ENDPOINT = 'http://upload.smugmug.com/'

  def initialize(ejson_file = '~/.photo_helper.ejson')
    ejson_file = File.expand_path(ejson_file)
    @secrets = Secrets.new(ejson_file, [:api_key, :api_secret])
    get_access_token if (!@secrets.access_token || !@secrets.access_secret)

    @http = get_access_token
    @uploader = get_access_token(UPLOAD_ENDPOINT)
  end

  def albums

  end

  def http(method, url, headers = {}, body = nil)
    headers.merge!({
      'Accept' => 'application/json'
    })

    response = @http.request(method, url, headers)
    raise "Request failed" unless response.kind_of? Net::HTTPSuccess
    JSON.parse(response.body)
  end

  def upload(image_path, album_id, headers={})
    image = File.open(image_path)

    headers.merge!({
      "Content-Type" => MimeMagic.by_path(image_path).type,
      "X-Smug-AlbumUri" => "/api/v2/album/#{album_id}",
      "X-Smug-ResponseType" => "JSON",
      "X-Smug-Version" => "v2",
      "charset" => "UTF-8",
      "Accept" => "JSON",
      "X-Smug-FileName" => File.basename(image_path),
      "Content-MD5" => Digest::MD5.file(image_path).hexdigest,
    })

    resp = @uploader.post("/", image, headers)
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
      raise "Not Implemented"
    end

    def get_access_token(endpoint = API_ENDPOINT)
      @consumer=OAuth::Consumer.new(
        @secrets.api_key, 
        @secrets.api_secret, 
        site: endpoint,
      )
      # # Create the access_token for all traffic
      OAuth::AccessToken.new(@consumer, @secrets.access_token, @secrets.access_secret) 
    end
end
