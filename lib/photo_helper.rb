require 'thor'

require 'helpers/printer'

require 'photo-helper/version'
require 'photo-helper/generate'
require 'photo-helper/delete'
require 'photo-helper/move'
require 'photo-helper/instagram'
require 'photo-helper/compress'

# todo: move to config file
# RAW_EXTENSION = "ORF"
RAW_EXTENSION = "dng"
JPEG_EXTENSION = "JPG"
PHOTOS_ROOT = "/Users/benjamincaldwell/Pictures/Pictures"
JPEG_ROOT ="/Users/benjamincaldwell/Pictures/jpegs"
IGNORE_FOLDERS = ["instagram", "exported", "edited"]

module PhotoHelper
  class CLI < Thor
    map "g" => "generate"
    map "d" => "delete"

    desc "version", "displays installed version"
    def version
      puts KubeDeploy::VERSION
    end

    register PhotoHelper::Generate, :generate, "generate", "Do something else"
    register PhotoHelper::Delete, :delete, "delete", "Do something else"
    register PhotoHelper::Instagram, :instagram, "instagram", "Do something else"
    register PhotoHelper::Move, :move, "move", "Do something else"
    register PhotoHelper::Compress, :compress, "compress", "Do something else"
  end
end
