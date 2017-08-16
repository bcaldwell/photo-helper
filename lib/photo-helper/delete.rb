require "helpers/trash"

module PhotoHelper
  class Delete < Thor
    include Thor::Actions

    map "j" => "jpeg"
    map "jpg" => "jpeg"
    map "jpgs" => "jpeg"
    map "jpegs" => "jpeg"

    desc "jpeg", "delete jpegs that have an raw with same name"
    method_option :folder, aliases: "-f", type: :string, default: "."
    method_option :hard, aliases: "-h", type: :boolean, default: false
    method_option :recursive, aliases: "-r", type: :boolean, default: false
    def jpeg(folder = nil)
      folder ||= options[:folder]
      puts folder

      search_path = File.expand_path(folder)
      jpeg_path = File.join(search_path, "jpegs")

      Dir.mkdir(jpeg_path) unless File.exists?(jpeg_path)

      files =
        if options[:recursive]
          Dir["#{search_path}/**/*.#{JPEG_EXTENSION}"]
        else
          Dir["#{search_path}/*.#{JPEG_EXTENSION}"]
        end

      files.each do |file|
        raw_file_name = File.basename(file.to_s, JPEG_EXTENSION) + RAW_EXTENSION
        next unless File.exist? File.join(search_path, raw_file_name)

        puts file

        if options[:hard]
          File.delete(file)
        else
          File.trash(file)
        end
      end

      next unless File.exist?(jpeg_path) && yes?("Delete jpeg folder?")
      say "Deleting jpeg folder", :red
      if options[:hard]
        File.delete(jpeg_path)
      else
        File.trash(jpeg_path)
      end

    end
  end
end
