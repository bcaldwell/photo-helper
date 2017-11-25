require "helpers/smugmug_api"
require "helpers/image_helper"
require "helpers/file_helper"

class SmugmugHelper
  attr_accessor :smugmug_api

  # to figure out what to delete, read all xmp files, loop through uploaded files and check xmp file
  
  PATH_REGEX = %r{^.+Pictures\/.+\/(\d{4})\/(\d{2})_.+\/[^_]+_([^\/]+)}
  
  def initialize(search_path)
    @search_path = search_path
    @smugmug = SmugmugAPI.new    
  end

  def parse_path
    if matches = "#{@search_path}/".to_s.match(PATH_REGEX)
      @year = matches[1]
      @month = Date::MONTHNAMES[matches[2].to_i].capitalize
      @location = matches[3].split("_").map(&:capitalize).join(' ')
    end
  end

  def album_name
    parse_path
    if @year && @month && @location
      folder = "#{@month} #{@year}"
      album_name_short = "#{@location} #{@month} #{@year}"
      File.join(@year, @month, album_name_short)
    else
      puts 'Unable to determine album from path'
    end
  end

  def image_list
    # todo: exclude exported path
    Dir["#{@search_path}/**/*.{#{IMAGE_EXTENSIONS.join(",")}}"].reject{ |p| FileHelper.ingore_file?(p) }
  end

  def merge_exported(images = image_list)
    exported = Dir["#{@search_path}/**/{Exported,exported}/*.{#{IMAGE_EXTENSIONS.join(",")}}"]
    exported_basenames = exported.map{ |p| File.basename(p, ".*") }
    images = images.reject { |p| exported_basenames.include? File.basename(p, ".*") }
    images.concat(exported)
  end

  def upload(album_name, pictures, reject_trash = true)
    album = @smugmug.get_or_create_album(album_name, album_url: @location&.downcase)
    puts "#{album[:web_uri]}\n"
    
    # remove uploaded pictures
    uploaded = @smugmug.image_list(album[:id])
    
    pictures = pictures.reject do |p|
      if reject_trash
        return true if ImageHelper.color_class(p) == "Trash"
      end
      uploaded.include? File.basename(p)
    end
    
    puts "Uploading #{pictures.count} jpegs"

    @smugmug.upload_images(pictures, album[:id], workers: 8)
  end

  def upload_dl
    @album_name = album_name
    @album_name = File.join("dl", @album_name)

    puts "Uploading all images to album #{@album_name}"
    upload(@album_name, image_list)
  end

  def upload_select
    @album_name = album_name
    pictures = image_list
    pictures = pictures.select{ |p| ImageHelper.is_select?(p)}
    pictures = merge_exported(pictures)

    puts "Uploading selects to album #{@album_name}"
    upload(@album_name, pictures)
  end
end
