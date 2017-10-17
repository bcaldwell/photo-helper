require "mini_magick"
require "helpers/file_helper"

module PhotoHelper
  class Compress < Thor
    include Thor::Actions

    method_option :recursive, aliases: "-r", type: :boolean, default: false
    method_option :overwrite, aliases: "-f", type: :boolean, default: false
    desc "images", "compress images in folder"
    def images(folder=nil)
      folder ||= options[:folder]

      search_path = File.expand_path(folder)

      files =
        if options[:recursive]
          Dir["#{search_path}/**/*"]
        else
          Dir["#{search_path}/*"]
        end

      files.each do |file|
        next if File.basename(file, ".*").end_with? (".min")
        next unless FileHelper.is_jpeg?(file)

        image = MiniMagick::Image.open(file)
        orig_size = image.size

        image.combine_options do |b|
          b.sampling_factor "4:2:0"
          b.strip
          b.interlace "JPEG"
          b.colorspace "RGB"
          b.quality 85
        end
        puts "#{file} (#{(orig_size / image.size) * 100}%)"

        output_path = 
          if options[:overwrite]
            file
          else
            File.join( File.dirname(file), File.basename(file, ".*") + ".min" + File.extname(file))
          end
 
        image.write output_path
      end
    end

    default_task :images
  end
end
