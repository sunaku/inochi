require 'tempfile'
require 'fileutils'

class TempDir
  attr_reader :path

  def initialize basename = nil, dirname = nil
    args = [basename || File.basename($0), dirname].compact
    file = Tempfile.new(*args)

    @path = file.path

    # replace the file with a directory
    file.close!
    FileUtils.mkdir_p @path

    # clean up on exit
    at_exit { close }
  end

  def close
    FileUtils.rm_rf @path
  end
end