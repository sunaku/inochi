module Inochi

  ##
  # Official name of this project.
  #
  PROJECT = 'Inochi'

  ##
  # Short single-line description of this project.
  #
  TAGLINE = 'Gives life to Ruby projects'

  ##
  # Address of this project's official home page.
  #
  WEBSITE = 'http://snk.tuxfamily.org/lib/inochi/'

  ##
  # Number of this release of this project.
  #
  VERSION = '3.0.0'

  ##
  # Date of this release of this project.
  #
  RELDATE = '2010-04-27'

  ##
  # Description of this release of this project.
  #
  def self.inspect
    "#{PROJECT} #{VERSION} (#{RELDATE})"
  end

  ##
  # Location of this release of this project.
  #
  INSTDIR = File.expand_path('../../..', __FILE__)

  ##
  # RubyGems required by this project during runtime.
  #
  # @example
  #
  #   RUNTIME = {
  #     # this project needs exactly version 1.2.3 of the "an_example" gem
  #     "an_example" => [ "1.2.3" ],
  #
  #     # this project needs at least version 1.2 (but not
  #     # version 1.2.4 or newer) of the "another_example" gem
  #     "another_example" => [ ">= 1.2" , "< 1.2.4" ],
  #
  #     # this project needs any version of the "yet_another_example" gem
  #     "yet_another_example" => [],
  #   }
  #
  RUNTIME = {
    'ember'       => [ '>= 0.3.0' , '< 1' ], # for eRuby templates
    'highline'    => [ '>= 1.5'   , '< 2' ], # for echoless password entry
    'mechanize'   => [ '~> 1'             ], # for publishing announcements
    'nokogiri'    => [ '>= 1.4'   , '< 2' ], # for parsing HTML and XML
    'rake'        => [ '>= 0.8.4' , '< 1' ], # for Inochi::Engine
    'ronn'        => [ '>= 0.7.0' , '< 1' ], # for making UNIX man pages
    'yard'        => [                    ], # for making API documentation
  }

  ##
  # RubyGems required by this project during development.
  #
  # @example
  #
  #   DEVTIME = {
  #     # this project needs exactly version 1.2.3 of the "an_example" gem
  #     "an_example" => [ "1.2.3" ],
  #
  #     # this project needs at least version 1.2 (but not
  #     # version 1.2.4 or newer) of the "another_example" gem
  #     "another_example" => [ ">= 1.2" , "< 1.2.4" ],
  #
  #     # this project needs any version of the "yet_another_example" gem
  #     "yet_another_example" => [],
  #   }
  #
  DEVTIME = {
    'dfect' => [ '>= 1.1.0', '< 2' ], # for unit testing
  }

  # establish gem version dependencies
  if respond_to? :gem
    [RUNTIME, DEVTIME].each do |deps|
      deps.each do |gem_name, gem_version|
        begin
          gem gem_name, *Array(gem_version)
        rescue LoadError => error
          warn "#{self.inspect}: #{error}"
        end
      end
    end
  end

end
