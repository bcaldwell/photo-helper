class FileHelper
	def self.directory(path) 
		File.dirname(path).split("/").last
	end

	def self.ingore_file?(path)
		IGNORE_FOLDERS.include? directory(path).downcase
	end
end