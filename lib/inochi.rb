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
    'rake'        => '~> 0',
    'rubyforge'   => '~> 1',              # for publishing gems to RubyForge
    'mechanize'   => '~> 0',              # for automating web browsing
    'trollop'     => '~> 1',              # for parsing command-line options
    'erbook'      => '~> 6',              # for processing the user manual
    'launchy'     => '~> 0',              # for launching a web browser
    'yard'        => nil,                 # for generating API documentation
    'addressable' => '~> 2',              # for parsing URIs properly
    'babelfish'   => '~> 0',              # for human language translation
  }
