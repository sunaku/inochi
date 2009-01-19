require File.join(File.dirname(__FILE__), 'inochi', 'inochi')

Inochi.init :Inochi,
  :version => '0.0.0',
  :release => '2009-01-19',
  :tagline => 'Gives life to RubyGems-based software',
  :website => 'http://snk.tuxfamily.org/lib/inochi',
  :require => {
    'rubyforge'   => '~> 1',  # for publishing gems to RubyForge
    'mechanize'   => '~> 0',  # for automating web browsing
    'trollop'     => '~> 1',  # for parsing command-line options
    'erbook'      => '~> 6',  # for processing the user manual
    'launchy'     => '~> 0',  # for launching a web browser
    'yard'        => nil,     # for generating API documentation
    'addressable' => '~> 2',  # for parsing URIs properly
  }
