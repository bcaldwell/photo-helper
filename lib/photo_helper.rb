# frozen_string_literal: true

require 'thor'

require 'helpers/printer'

require 'photo-helper/version'
require 'photo-helper/generate'
require 'photo-helper/delete'
require 'photo-helper/move'
require 'photo-helper/instagram'
require 'photo-helper/compress'
require 'photo-helper/smugmug'
require 'photo-helper/screensaver'

# TODO: move to config file
RAW_EXTENSION = 'dng'.freeze
RAW_EXTENSIONS = [RAW_EXTENSION, 'DNG', 'ORF', 'RAF'].freeze
JPEG_EXTENSION = 'JPG'.freeze
JPEG_EXTENSIONS = [JPEG_EXTENSION, 'jpg', 'jpeg'].freeze
IMAGE_EXTENSIONS = JPEG_EXTENSIONS.dup.concat([])
PHOTOS_ROOT = File.expand_path('~/Pictures/Pictures')
BEST_OF_ROOT = File.expand_path("~/Pictures/Pictures/Best\ of")
SCREENSAVER_ROOT = File.expand_path('~/Pictures/screensaver')
JPEG_ROOT = File.expand_path('~/Pictures/jpegs')
IGNORE_FOLDERS = %w[instagram exported edited].freeze
SELECT_COLOR_TAGS = ['Winner', 'Winner alt', 'Superior', 'Superior alt', 'Typical', 'Typical alt'].freeze
SELECT_RATING = 1 # greater than or equal to

module PhotoHelper
  class CLI < Thor
    map 'g' => 'generathte'
    map 'd' => 'delete'
    map 's' => 'smugmug'

    desc 'version', 'displays installed version'
    def version
      puts PhotoHelper::VERSION
    end

    register PhotoHelper::Generate, :generate, 'generate', 'Do something else'
    register PhotoHelper::Delete, :delete, 'delete', 'Do something else'
    register PhotoHelper::Instagram, :instagram, 'instagram', 'Do something else'
    register PhotoHelper::Move, :move, 'move', 'Do something else'
    register PhotoHelper::Compress, :compress, 'compress', 'Do something else'
    register PhotoHelper::Smugmug, :smugmug, 'smugmug', 'Interface with Smugmug'
    register PhotoHelper::Screensaver, :screensaver, 'screensaver', 'Move best photos to screensaver folder and compress'
  end
end
