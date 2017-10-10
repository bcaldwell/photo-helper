require "helpers/trash"
require 'fileutils'
require 'helpers/file_helper'

module PhotoHelper
  class Move < Thor
    include Thor::Actions

    map "j" => "jpeg"
    map "jpg" => "jpeg"
    map "jpgs" => "jpeg"
    map "jpegs" => "jpeg"

    desc "jpeg", "delete jpegs that have an raw with same name"
    method_option :folder, aliases: "-f", type: :string, default: "."
    method_option :recursive, aliases: "-r", type: :boolean, default: false
    def jpeg(folder = nil)
      folder ||= options[:folder]
      puts folder

      search_path = File.expand_path(folder)

      files =
        if options[:recursive]
          Dir["#{search_path}/**/*.#{JPEG_EXTENSION}"]
        else
          Dir["#{search_path}/*.#{JPEG_EXTENSION}"]
        end

      files.each do |file|
        next if FileHelper.ingore_file?(file)
        relative_path = Pathname.new(file).relative_path_from(Pathname.new(PHOTOS_ROOT)).to_s
        new_path = File.join(JPEG_ROOT, relative_path)
        path_dir = File.dirname(new_path)

        FileUtils.mkdir_p path_dir unless File.exists? path_dir

        FileUtils.mv file, new_path 

      end
    end
  end
end
