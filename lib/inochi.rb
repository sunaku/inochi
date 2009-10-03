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
  :version => '1.1.1',
  :release => '2009-10-03',
  :website => 'http://snk.tuxfamily.org/lib/inochi/',
  :tagline => 'Gives life to RubyGems-based software',
  :require => {
    'trollop'        => '~> 1',                 # for parsing command-line
    'launchy'        => ['~> 0', '>= 0.3.3'],   # for launching a browser
  },
  :develop => {
    'rake'           => ['~> 0', '>= 0.8.4'],
    'rubyforge'      => '~> 2',                 # for publishing gems
    'mechanize'      => '~> 0',                 # for web automation
    'voloko-sdoc'    => ['~> 0', '>= 0.2.10'],  # for API docs
    'addressable'    => '~> 2',                 # for parsing URIs properly
    'erbook'         => '~> 7',                 # for generating user manual
    'babelfish'      => '~> 0',                 # for language translation
    'relevance-rcov' => nil,                    # for code coverage statistics
    'flay'           => nil,                    # for code quality analysis
    'reek'           => nil,                    # for code quality analysis
    'roodi'          => nil,                    # for code quality analysis
    'ZenTest'        => '~> 4',                 # for the `multiruby` tool
  }
