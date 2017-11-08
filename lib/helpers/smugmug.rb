require 'helpers/secrets'
require 'oauth'
require 'uri'
require 'json'

class Smugmug
  attr_accessor :http, :uploader
  OAUTH_ORIGIN = 'https://secure.smugmug.com'
  REQUEST_TOKEN_URL = '/services/oauth/1.0a/getRequestToken'
  ACCESS_TOKEN_URL = '/services/oauth/1.0a/getAccessToken'
  AUTHORIZE_URL = '/services/oauth/1.0a/authorize'
  API_ENDPOINT = 'https://api.smugmug.com'
  UPLOAD_ENDPOINT = 'https://upload.smugmug.com/'

  def initialize(ejson_file = '~/.photo_helper.ejson')
    ejson_file = File.expand_path(ejson_file)
    @secrets = Secrets.new(ejson_file, [:api_key, :api_secret])
    get_access_token if (!@secrets.access_token || !@secrets.access_secret)

    @http = get_access_token
    @uploader = get_access_token(UPLOAD_ENDPOINT)

    # puts http('get', '/api/v2!authuser')["Response"]["User"]["ImageCount"]
    # puts @uploader.post("/").body

    upload("/Users/benjamincaldwell/Pictures/Pictures/2017/10_Oct/27-29_ yosemite/Oct27/2017-10-27-yosemite-0.JPG", "/api/v2/album/kxjXff")
  end

  def albums

  end

  def http(method, url, headers = {}, body = nil)
    headers.merge!({
      'Accept' => 'application/json'
    })

    response = @http.send(method, url, headers)
    raise "Request failed" unless response.kind_of? Net::HTTPSuccess
    JSON.parse(response.body)
  end

  def upload(image_path, album_uri, headers={})
    image = File.open(image_path)
    headers.merge!({
      "X-Smug-AlbumUri": album_uri,
      "X-Smug-ResponseType": "JSON",
      "X-Smug-Version": "v2",
    })

    @uploader.post("/", image, headers)
  end

  private
    def get_access_token
      raise "Not Implemented"
    end

    def get_access_token(endpoint = API_ENDPOINT)
      @consumer=OAuth::Consumer.new @secrets.api_key, 
        @secrets.api_secret, 
        {site: endpoint}

      # # Create the access_token for all traffic
      OAuth::AccessToken.new(@consumer, @secrets.access_token, @secrets.access_secret) 
    end
end
