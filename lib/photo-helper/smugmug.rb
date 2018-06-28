# frozen_string_literal: true

require 'helpers/smugmug_album'
require 'date'
require 'helpers/image_helper'

module PhotoHelper
  class Smugmug < Thor
    include Thor::Actions

    map 's' => 'sync'
    desc 'sync', "sync folder's non-raw images with smugmug"
    method_option :folder, aliases: '-f', type: :string, default: '.'
    method_option :recursive, aliases: '-r', type: :boolean, default: false
    method_option :dry_run, aliases: '-d', type: :boolean, default: false
    method_option :no_delete, type: :boolean, default: false
    def sync(folder = nil, album_name = nil)
      search_path = File.expand_path(folder)

      if options[:recursive]
        SmugmugAlbumHelper.recursive_sync(search_path)
        return
      end

      if album_name
        @smugmug = SmugmugAlbumHelper.new(search_path, album_name)
        @smugmug.upload_dl(album_name)
      else
        SmugmugAlbumHelper.sync(search_path)
      end
    end

    desc 'oauth', 'fetch oauth credentials'
    def oauth
      SmugmugAPI.new.request_access_token
    end

    desc 'albums', 'list albums with their weburl'
    def albums
      @smugmug = SmugmugAPI.new
      albums = @smugmug.albums_long

      albums_tree = {}
      output = ["# Photos"]

      albums.each do |a|
        parts = a[:path].split('/')
        next if parts[0] == "Trash"

        album_name = parts.pop
        parts.each_with_index do |part, i|
          if i == 0
            albums_tree[part] ||= {}
          else
            parts[0..(i - 1)].inject(albums_tree, :fetch)[part] ||= {}
          end
        end

        parts[0..-1].inject(albums_tree, :fetch)[album_name] = "[#{a[:name]}](#{a[:web_uri]})"
      end

      # depth first search
      stack = albums_tree.keys.map { |a| [a] }
      stack.sort_by! do |key|
        next key.first.to_i if key.first =~ /^\d+$/
        next Float::INFINITY
      end

      until stack.empty?
        key = stack.pop
        item = key.inject(albums_tree, :fetch)
        next if key.first == "dl"

        if item.is_a?(Hash)
          stack.concat(item.keys.map{|a| key.clone.push(a)})
          output.push("#{'#'*key.count} #{key.last}")
          next
        end

        begin
          dl_item = ["dl"].concat(key).inject(albums_tree, :fetch)
          output.push("  **Selects: ** #{item}\n  **All: ** #{dl_item}")
        rescue
          output.push(item)
        end
      end

      puts output.join("\n\n")
    end
  end
end
