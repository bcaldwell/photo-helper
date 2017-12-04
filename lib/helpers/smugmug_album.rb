# frozen_string_literal: true
require "helpers/smugmug_api"
require "helpers/image_helper"
require "helpers/file_helper"
require 'set'

class SmugmugAlbumHelper
  attr_accessor :smugmug_api

  # to figure out what to delete, read all xmp files, loop through uploaded files and check xmp file

  PATH_REGEX = %r{^.+Pictures\/.+\/(\d{4})\/(\d{2})_.+\/[^_]+_([^\/]+)}
  KEYWORD_WHITELITS = %w("instagram exported")

  def initialize(search_path, album = nil)
    @search_path = Pathname.new(search_path)
    @smugmug = SmugmugAPI.new

    @album_name = album || album_name

    @album = @smugmug.get_or_create_album(@album_name, album_url: @location&.downcase)

    @dl_album_name = File.join("dl", @album_name)
    @dl_album = @smugmug.get_or_create_album(@dl_album_name, album_url: @location&.downcase)

    @keyword_list = Set.new
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
      album_name_short = "#{@location} #{@month} #{@year}"
      File.join(@year, @month, album_name_short)
    else
      puts 'Unable to determine album from path'
    end
  end

  def image_list
    Dir["#{@search_path}/**/*.{#{IMAGE_EXTENSIONS.join(',')}}"].reject { |p| FileHelper.ingore_file?(p) }
  end

  def exported_list
    Dir["#{@search_path}/**/{Exported,exported}/*.{#{IMAGE_EXTENSIONS.join(',')}}"]
  end

  def instagram_list
    Dir["#{@search_path}/**/{Instagram,instagram}/*.{#{IMAGE_EXTENSIONS.join(',')}}"]
  end

  def merge_exported(images = image_list, concat = false)
    exported = Dir["#{@search_path}/**/{Exported,exported}/*.{#{IMAGE_EXTENSIONS.join(',')}}"]
    unless concat
      exported_basenames = exported.map { |p| File.basename(p, ".*") }
      images = images.reject { |p| exported_basenames.include? File.basename(p, ".*") }
    end
    images.concat(exported)
  end

  def uploaded_to_hash(album)
    uploaded = @smugmug.images(album[:id])
    uploaded_hash = {}
    uploaded.each do |u|
      filename = File.basename(u[:filename], ".*")
      push_hash_array(uploaded_hash, filename, u)
    end
    uploaded_hash
  end

  def image_list_to_hash(images)
    image_list_hash = {}
    images.each do |i|
      filename = File.basename(i, ".*")
      tags = image_dir_keywords(i)
      @keyword_list.merge(tags) if tags
      push_hash_array(image_list_hash, filename, file: i,
        keywords: tags,
        md5: Digest::MD5.file(i).hexdigest)
    end
    image_list_hash
  end

  def sync(album, image_list_hash, reject_trash = true)
    uploaded_hash = uploaded_to_hash(album)

    to_upload = {}
    to_update = {}
    to_delete = []

    image_list_hash.each do |filename, images|
      images.each do |image|
        next unless ImageHelper.is_jpeg?(image[:file])
        next if reject_trash && ImageHelper.color_class(image[:file]) == "Trash"

        upload_image = true

        if uploaded_hash.key?(filename)
          !uploaded_hash[filename].each do |uploaded|
            next unless uploaded_match_requested?(image, uploaded)

            # & returns if in both arrays
            upload_image = false
            if uploaded[:md5] != image[:md5]
              push_hash_array(to_update, image[:keywords], image.merge!(uri: uploaded[:uri]))
            end
            break
          end
        end

        if upload_image
          push_hash_array(to_upload, image[:keywords], image[:file])
        end
      end
    end

    uploaded_hash.each do |filename, uploaded_images|
      uploaded_images.each do |uploaded|
        if image_list_hash.key?(filename)
          image_hash = image_list_hash[filename].find do |image|
            uploaded_match_requested?(image, uploaded)
          end
          to_delete.push(uploaded) if image_hash.nil?
          to_delete.push(uploaded) if reject_trash && ImageHelper.color_class(image_hash[:file]) == "Trash"
        else
          to_delete.push(uploaded)
        end
      end
    end

    to_upload.each do |keywords, images|
      puts keywords
      upload(album, images, keywords)
    end

    if to_delete.any?
      puts "Deleting #{to_delete.count} images"
      to_delete.each do |uploaded|
        puts uploaded[:filename]
        @smugmug.http(:delete, uploaded[:uri])
      end
    end

    to_update.each do |keywords, images|
      puts keywords
      update(album, images, keywords)
    end
  end

  def upload(album, pictures, keywords = nil)
    puts "Uploading #{pictures.count} jpegs"

    headers = {}
    headers["X-Smug-Keywords"] = keywords.join(",") unless keywords.nil?

    @smugmug.upload_images(pictures, album[:id], headers, workers: 8, filename_as_title: true)
  end

  def update(album, pictures, keywords = nil)
    puts "Updating #{pictures.count} jpegs"

    headers = {}
    headers["X-Smug-Keywords"] = keywords.join(",") unless keywords.nil?

    @smugmug.update_images(pictures, album[:id], headers, workers: 8, filename_as_title: true)
  end

  def upload_dl
    @keyword_list = Set.new
    puts "Uploading all images to album #{@album_name} --> #{@dl_album[:web_uri]}\n"

    @image_list = image_list_to_hash(image_list)
    @image_list = merge_hash_array(@image_list, image_list_to_hash(exported_list))
    @image_list = merge_hash_array(@image_list, image_list_to_hash(instagram_list))

    sync(@dl_album, @image_list, true)
  end

  def upload_select
    @keyword_list = Set.new

    pictures = image_list
    pictures = pictures.select { |p| ImageHelper.is_select?(p) }
    pictures = merge_exported(pictures)

    puts "Uploading selects to album #{@album_name} --> #{@album[:web_uri]}\n"

    @image_list = image_list_to_hash(pictures)

    sync(@album, @image_list, true)
  end

  private

  def push_hash_array(hash, key, item)
    hash[key] = [] unless hash.key?(key)
    hash[key].push(item)
    hash
  end

  def merge_hash_array(hash1, hash2)
    hash2.each do |key, value|
      hash1[key] = [] unless hash1.key?(key)
      hash1[key].concat(value)
    end
    hash1
  end

  def image_dir_keywords(image)
    rel = Pathname.new(image).relative_path_from(@search_path).to_s.split("/")
    # ignore first and last parts
    rel &= KEYWORD_WHITELITS
    return nil if rel.empty?
    rel
  end

  def uploaded_match_requested?(image, uploaded)
    if image[:keywords].nil?
      # empty from keyword list
      return true if uploaded[:keywords].nil? || @keyword_list & uploaded[:keywords] == Set.new
    else
      return true if image[:keywords] - uploaded[:keywords] == []
    end
    false
  end
end
