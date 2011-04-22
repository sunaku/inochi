require 'fileutils'
require 'digest/sha1'

module Inochi
  module Generate
    extend self

    ##
    # Notify the user about some action being performed.
    #
    def notify action, message
      printf "%16s  %s\n", action, message
    end

    ##
    # Writes the given contents to the file at the given
    # path.  If the given path already exists, then a
    # backup is created before invoking the given block.
    #
    def generate path, content # :yields: old_file, new_file, output_file
      if File.exist? path
        old_digest = Digest::SHA1.digest(File.read(path))
        new_digest = Digest::SHA1.digest(content)

        if old_digest == new_digest
          notify :skip, path
        else
          notify :update, path
          cur, old, new = path, "#{path}.old", "#{path}.new"

          FileUtils.cp cur, old, :preserve => true
          File.write new, content

          yield old, new, cur if block_given?
        end
      else
        notify :create, path
        FileUtils.mkdir_p File.dirname(path)
        File.write path, content
      end
    end
  end
end

unless File.respond_to? :write
  ##
  # Writes the given content to the given file.
  #
  def File.write path, content
    open(path, 'wb') {|f| f.write content }
  end
end
