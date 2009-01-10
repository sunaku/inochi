require File.join(File.dirname(__FILE__), 'inochi', 'inochi')

Inochi.init :Inochi,
  :version => '0.0.1',
  :release => '2008-12-31',
  :tagline => 'Gives life to RubyGems-based software',
  :website => 'http://snk.tuxfamily.org/lib/inochi',
  :require => {
    'rubyforge' => '~> 1',      # for publishing gems to RubyForge
    'trollop'   => '~> 1.10',   # for parsing command-line options
    'erbook'    => '5.0.0',     # for processing the user manual
    'yard'      => nil,         # for generating API documentation
    'tmail'     => nil,         # for handling e-mail messages
    'highline'  => nil,         # for asking for passwords
  }
