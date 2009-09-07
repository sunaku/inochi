#--
# Copyright protects this work.
# See LICENSE file for details.
#++

require 'rubygems'

module Inochi
  libs = File.dirname(__FILE__)
  $LOAD_PATH << libs unless $LOAD_PATH.include? libs
end

require 'inochi/init'
require 'inochi/main'
require 'inochi/rake'
require 'inochi/book'
require 'inochi/util'

Inochi.init :Inochi,
  :version => '1.1.0',
  :release => '2009-09-06',
  :website => 'http://snk.tuxfamily.org/lib/inochi/',
  :tagline => 'Gives life to RubyGems-based software',
  :require => {
    'trollop'        => '~> 1',      # for parsing command-line options
    'launchy'        => '>= 0.3.3',  # for launching a web browser
  },
  :develop => {
    'rake'           => '>= 0.8.4',
    'rubyforge'      => '~> 1',      # for publishing gems to RubyForge
    'mechanize'      => '~> 0',      # for automating web browsing
    'voloko-sdoc'    => '>= 0.2.10', # for generating API documentation
    'addressable'    => '~> 2',      # for parsing URIs properly
    'erbook'         => '~> 7',      # for processing the user manual
    'babelfish'      => '~> 0',      # for human language translation
    'spicycode-rcov' => nil,         # for code coverage statistics
    'flay'           => nil,         # for code quality analysis
    'reek'           => nil,         # for code quality analysis
    'roodi'          => nil,         # for code quality analysis
    'ZenTest'        => '~> 4',      # for the `multiruby` tool
  }
