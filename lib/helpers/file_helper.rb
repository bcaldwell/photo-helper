class FileHelper
  def self.directory(path)
    File.dirname(path).split('/').last
  end

  def self.ingore_file?(path)
    IGNORE_FOLDERS.include? directory(path).downcase
  end

  def self.is_jpeg?(path)
    # remove . from the beginning
    extension = File.extname(path)[1..-1]
    return false if extension.nil?
    JPEG_EXTENSIONS.include? extension.downcase
  end
end
