# exiftool -b -previewimage 2017-09-24-seattle-23.ORF>hi.jpg

module PhotoHelper
  class Generate < Thor
    include Thor::Actions

    map 'j' => 'jpeg'
    map 'jpg' => 'jpeg'
    map 'jpgs' => 'jpeg'
    map 'jpegs' => 'jpeg'

    desc 'jpeg', 'generate jpeg from raw files'
    method_option :folder, aliases: '-f', type: :string, default: '.'
    method_option :dpi, type: :numeric, default: 350
    def jpeg(folder = nil)
      folder ||= options[:folder]
      puts folder

      search_path = File.expand_path(folder)
      jpeg_path = File.join(search_path, 'jpegs')

      Dir.mkdir(jpeg_path) unless File.exist?(jpeg_path)

      files = Dir["#{search_path}/*.{#{RAW_EXTENSIONS}.join(','))}"]

      files.each do |file|
        jpeg_file_name = File.basename(file.to_s, ".*") + JPEG_EXTENSION
        next if File.exist? File.join(search_path, jpeg_file_name)
        puts file

        `sips -s format jpeg #{file} -s dpiHeight #{options[:dpi]} -s dpiWidth #{options[:dpi]} --out "./jpegs/#{jpeg_file_name}.JPG"`
      end
    end
  end
end
