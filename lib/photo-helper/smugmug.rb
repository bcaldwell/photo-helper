require 'helpers/smugmug_api'
require 'date'
require 'byebug'

module PhotoHelper
  class Smugmug < Thor
    include Thor::Actions
    # PATH_REGEX = %r{^.+Pictures/Pictures/(?<year>.+?(?=/))/(?<month>[0-9][0-9])_.+_(?<location>.+?(?=/))}
    PATH_REGEX = %r{^.+Pictures\/Pictures\/([^\/]+)\/([0-9][0-9])_.+_([^\/]+)}

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
          folder = "#{Date::MONTHNAMES[matches[2].to_i].capitalize} #{matches[1]}"
          album_name_short = "#{matches[3].sub('_', ' ').capitalize} #{matches[1]}"
          album_name = File.join("/", folder, album_name_short)
        else
          puts 'Unable to determine album from path'
          return
        end
      end
      puts album_name

      @smugmug = SmugmugAPI.new
      album = @smugmug.albums_long.select{|a| a[:path] == album_name}
      puts album
    end
  end
end
