require 'helpers/smugmug_album'
require 'date'
require 'helpers/image_helper'

module PhotoHelper
  class Smugmug < Thor
    include Thor::Actions

    map 's' => 'sync'
    desc 'sync', "sync folder's non-raw images with smugmug"
    method_option :folder, aliases: '-f', type: :string, default: '.'
    method_option :recursive, aliases: '-r', type: :boolean, default: false
    method_option :dry_run, aliases: '-d', type: :boolean, default: false
    def sync(folder = nil, album_name = nil)
      search_path = File.expand_path(folder)

      @smugmug = SmugmugAlbumHelper.new(search_path)

      @smugmug.upload_select
      puts("\n")
      # if album_name
      #   @smugmug.upload(album_name, @smugmug.image_list)
      # else
      @smugmug.upload_dl
      # end
    end

    desc 'oauth', "fetch oauth credentials"
    def oauth()
      SmugmugAPI.new.request_access_token
    end

    desc 'albums', "list albums with their weburl"
    method_option :folder, aliases: '-f', type: :string, default: '.'
    def albums(folder = nil, album_name = nil)
      @smugmug = SmugmugAPI.new
      albums = @smugmug.albums_long

      current_month = albums.first[:path].split("/")[1]
      output = ["# Photos", "## #{current_month}"]

      albums.each do |a|
        month = a[:path].split("/")[1]
        next unless month
        if month != current_month
          current_month = month
          output.push("## #{current_month}")
        end
        output.push("[#{a[:name]}](#{a[:web_uri].gsub('http://', 'https://')})")
      end

      puts output.join("\n\n")
    end
  end
end
