require 'helpers/smugmug_api'
require 'date'
require 'helpers/image_helper'

module PhotoHelper
  class Smugmug < Thor
    include Thor::Actions
    PATH_REGEX = %r{^.+Pictures\/.+\/(\d{4})\/(\d{2})_.+\/[^_]+_([^\/]+)}

    map 's' => 'sync'

    desc 'sync', "sync folder's non-raw images with smugmug"
    method_option :folder, aliases: '-f', type: :string, default: '.'
    method_option :recursive, aliases: '-r', type: :boolean, default: false
    method_option :dry_run, aliases: '-d', type: :boolean, default: false
    def sync(folder = nil, album_name = nil)
      search_path = File.expand_path(folder)
      puts search_path
      unless album_name
        if matches = "#{search_path}/".to_s.match(PATH_REGEX)
          year = matches[1]
          month = Date::MONTHNAMES[matches[2].to_i].capitalize
          location = matches[3].split("_").map(&:capitalize).join(' ')

          folder = "#{month} #{year}"
          album_name_short = "#{location} #{month} #{year}"
          album_name = File.join(year, month, album_name_short)
        else
          puts 'Unable to determine album from path'
          return
        end
      end
      puts "Using album: #{album_name}"

      @smugmug = SmugmugAPI.new
      album = @smugmug.get_or_create_album(album_name, album_url: location.downcase)
      puts "#{album[:web_uri]}\n"
      pictures = Dir["#{search_path}/**/*.JPG"]      
      
      # remove uploaded pictures
      uploaded = @smugmug.image_list(album[:id])
      pictures = pictures.reject { |p| (ImageHelper.color_class(p) == "Trash" or uploaded.include? File.basename(p)) }
      puts "Uploading #{pictures.count} jpegs"

      @smugmug.upload_images(pictures, album[:id], workers: 8)
    end
  end
end
