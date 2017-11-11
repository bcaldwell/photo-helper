class ImageHelper
  IMAGE_CLASS_REGEX = %r{xmp:Label="(.+)"}
    
  def self.color_class(image)
    xmp = File.join(File.dirname(image), File.basename(image, ".*") + ".XMP")
    return unless File.exists?(xmp)
    contents = File.read(xmp)
    matches = contents.match(IMAGE_CLASS_REGEX)
    matches[1] if matches      
  end
end
