class ImageHelper
  IMAGE_CLASS_REGEX = %r{xmp:Label="(.+)"}
  RATING_REGEX = %r{xmp:Rating="(.+)"}
    
  def self.xmp(image)
    xmp = File.join(File.dirname(image), File.basename(image, ".*") + ".XMP")
    return unless File.exists?(xmp)
    File.read(xmp)
  end

  def self.color_class(image)
    contents = xmp(image)
    matches = contents.match(IMAGE_CLASS_REGEX)
    matches[1] if matches
  end

  def self.contains_color_class?(image, values)
    values = [values] unless values.is_a? Array
    values.include? color_class(image)
  end

  def self.rating(image)
    contents = xmp(image)
    matches = contents.match(RATING_REGEX)
    matches[1] if matches
  end

  def self.is_select?(image)
    contains_color_class?(image, SELECT_COLOR_TAGS)
  end

  def self.is_5_star?(image)
    rating(image) == '5'
  end
end
