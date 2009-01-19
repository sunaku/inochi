require File.join(File.dirname(__FILE__), 'inochi', 'inochi')

Inochi.init :Inochi,
  :version => '0.0.1',
  :release => '2008-12-31',
  :tagline => 'Gives life to RubyGems-based software',
  :website => 'http://snk.tuxfamily.org/lib/inochi',
  :require => {
    'rubyforge'   => '~> 1',    # for publishing gems to RubyForge
    'mechanize'   => '0.9.0',   # for automating RAA.ruby-lang.org
    'trollop'     => '~> 1.10', # for parsing command-line options
    'erbook'      => '5.0.0',   # for processing the user manual
    'launchy'     => '~> 0.3',  # for launching a web browser
    'yard'        => nil,       # for generating API documentation
    'addressable' => '~> 2',    # for parsing URIs properly
  }
