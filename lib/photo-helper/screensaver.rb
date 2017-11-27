require 'helpers/file_helper'
require 'photo-helper/compress'

module PhotoHelper
  class Screensaver < Thor
    include Thor::Actions

    method_option :overwrite, aliases: '-o', type: :boolean, default: false
    desc 'move', 'Move best photos to screensaver folder and compress'
    def move
      files = Dir["#{BEST_OF_ROOT}/**/*"]

      files.each do |file|
        next unless FileHelper.is_jpeg?(file)
        dest = File.join(SCREENSAVER_ROOT, File.basename(file))
        next if File.exist?(dest)
        puts file
        FileUtils.copy(file, dest)
      end

      puts 'Compressing'

      compress = PhotoHelper::Compress.new
      compress.options = { overwrite: true }
      compress.images(SCREENSAVER_ROOT)
    end

    default_task :move
  end
end
