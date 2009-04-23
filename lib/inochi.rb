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
    'trollop'     => '~> 1',     # for parsing command-line options
    'launchy'     => '>= 0.3.3', # for launching a web browser
  },
  :develop => {
    'rake'           => ['>= 0.8.4', '< 0.9'],
    'rubyforge'      => '~> 1',              # for publishing gems to RubyForge
    'mechanize'      => '~> 0',              # for automating web browsing
    'voloko-sdoc'    => ['>= 0.2.10', '< 1'],# for generating API documentation
    'addressable'    => '~> 2',              # for parsing URIs properly
    'erbook'         => ['>= 6.1.1',  '< 7'],# for processing the user manual
    'babelfish'      => '~> 0',              # for human language translation
    'spicycode-rcov' => nil,                 # for code coverage statistics
    'flay'           => nil,                 # for code quality analysis
    'reek'           => nil,                 # for code quality analysis
    'roodi'          => nil,                 # for code quality analysis
    'ruby_diff'      => nil,                 # for code quality analysis
    'ZenTest'        => ['>= 4.0.0', '< 5'], # for the `multiruby` tool
  }
