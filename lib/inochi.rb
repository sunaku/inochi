require 'rubygems'

module Inochi
end

$LOAD_PATH << File.dirname(__FILE__)
require 'inochi/init'
require 'inochi/main'
require 'inochi/rake'
require 'inochi/book'
require 'inochi/util'

Inochi.init :Inochi,
  :version => '0.3.0',
  :release => '2009-02-12',
  :website => 'http://snk.tuxfamily.org/lib/inochi',
  :tagline => 'Gives life to RubyGems-based software',
  :require => {
    'trollop' => '~> 1',     # for parsing command-line options
    'launchy' => '>= 0.3.3', # for launching a web browser
  }
