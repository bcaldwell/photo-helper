class FileHelper
	def self.directory(path) 
		File.dirname(path).split("/").last
	end

	def self.ingore_file?(path)
		IGNORE_FOLDERS.include? directory(path).downcase
	end

	def self.is_jpeg?(path)
		extension = File.extname(path)
		[".jpeg", ".jpg"].include? extension.downcase
	end
end