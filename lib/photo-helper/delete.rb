require 'helpers/trash'
require 'helpers/file_helper'

module PhotoHelper
  class Delete < Thor
    include Thor::Actions

    map 'j' => 'jpeg'
    map 'jpg' => 'jpeg'
    map 'jpgs' => 'jpeg'
    map 'jpegs' => 'jpeg'

    desc 'jpeg', 'delete jpegs that have an raw with same name'
    method_option :folder, aliases: '-f', type: :string, default: '.'
    method_option :hard, aliases: '-h', type: :boolean, default: false
    method_option :recursive, aliases: '-r', type: :boolean, default: false
    def jpeg(folder = nil)
      folder ||= options[:folder]
      puts folder

      search_path = File.expand_path(folder)
      jpeg_path = File.join(search_path, 'jpegs')

      files =
        if options[:recursive]
          Dir["#{search_path}/**/*.{#{JPEG_EXTENSIONS.join(',')}}"]
        else
          Dir["#{search_path}/*.{#{JPEG_EXTENSIONS.join(',')}}"]
        end

      files.each do |file|
        has_raw = false
        RAW_EXTENSIONS.each do |extension|
          raw_file_name = "#{File.basename(file.to_s, '.*')}.#{extension}"
          has_raw = true if File.exist? File.join(File.dirname(file.to_s), raw_file_name)
        end
        next if FileHelper.ingore_file?(file)
        puts file

        if options[:hard]
          File.delete(file)
        else
          File.trash(file)
        end
      end

      return unless File.exist?(jpeg_path) && yes?('Delete jpeg folder?')
      say 'Deleting jpeg folder', :red
      if options[:hard]
        File.delete(jpeg_path)
      else
        File.trash(jpeg_path)
      end
    end
  end
end
