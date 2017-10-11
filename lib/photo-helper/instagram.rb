require "helpers/file_helper"

module PhotoHelper
  class Instagram < Thor
    include Thor::Actions

    def self.folders
    	["instagram"]
	  end

	  def self.album
	  	"Instagram"
	  end

	  desc "load", "load all pictures in instagram folders into apple photos"

    method_option :recursive, aliases: "-r", type: :boolean, default: false
    method_option :folder, aliases: "-f", type: :string, default: "."

    def self.osascript(script)
		  system 'osascript', *script.split(/\n/).map { |line| ['-e', line] }.flatten
		end

	  def load(folder=nil)
      folder ||= options[:folder]

      search_path = File.expand_path(folder)

      files =
        if options[:recursive]
          Dir["#{search_path}/**/*"]
        else
          Dir["#{search_path}/*"]
        end

        pictures = []

        files.each do |file|
        	folder = FileHelper.directory(file).downcase
          puts folder
        	next unless PhotoHelper::Instagram.folders.include? (folder)
        	pictures.concat([file])
	      end
        return unless pictures.any?

	      puts pictures
      	PhotoHelper::Instagram.osascript <<-END
				 tell application "Photos"
				   activate
				   delay 2
				   set ablum to get album "#{PhotoHelper::Instagram.album}"
				   set imageList to {"#{pictures.join('","')}"}
				   import imageList into ablum skip check duplicates no
				 end tell
				END

      end

      default_task :load
	end
end