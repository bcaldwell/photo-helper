# https://github.com/jphastings/trash/blob/master/trash.rb

class File
  # Moves the file whose filename is given to the Trash, Recycle Bin or equivalent of the OS being used.
  #
  # Will return a NotImplementtedError if your OS is not implemented.
  def self.trash(filename)
    filename = self.expand_path(filename)
    
    # Different Operating systems
    case Sys::Uname.sysname
    when "Darwin"
      if filename =~ /^\/Volumes\/(.+?)\//
        # External Volume, send to /Volumes/-volume name-/.Trashes/501/
        FileUtils.mv(filename,"/Volumes/#{$1}/.Trashes/501/")
      else
        # Main drive, move to ~/.Trash/
        self.move(filename,self.expand_path("~/.Trash/"))
      end
    when /^Microsoft Windows/
      raise NotImplementedError, ""
    end
  end
end
