require File.join(File.dirname(File.expand_path(__FILE__)), 'inochi', 'inochi')

Inochi.init :Inochi,
  :version => '0.1.0',
  :release => '2009-01-19',
  :website => 'http://snk.tuxfamily.org/lib/inochi',
  :tagline => 'Gives life to RubyGems-based software',
  :require => {
    'rake'        => '~> 0',
    'rubyforge'   => '~> 1',  # for publishing gems to RubyForge
    'mechanize'   => '~> 0',  # for automating web browsing
    'trollop'     => '~> 1',  # for parsing command-line options
    'launchy'     => '~> 0',  # for launching a web browser
    'yard'        => nil,     # for generating API documentation
    'addressable' => '~> 2',  # for parsing URIs properly
  }
