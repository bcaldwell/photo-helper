require 'thor'

require 'helpers/printer'

require 'photo-helper/version'
require 'photo-helper/generate'
require 'photo-helper/delete'

# todo: move to config file
RAW_EXTENSION = "ORF"
JPEG_EXTENSION = "JPG"

module PhotoHelper
  class CLI < Thor
    map "g" => "generate"
    map "d" => "delete"

    desc "version", "displays installed version"
    def version
      puts KubeDeploy::VERSION
    end
    # default_task :version

    register PhotoHelper::Generate, :generate, "generate", "Do something else"
    register PhotoHelper::Delete, :delete, "delete", "Do something else"
  end
end
