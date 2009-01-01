require File.join(File.dirname(__FILE__), 'inochi', 'inochi')

Inochi.init :Inochi,
  :version => '0.0.1',
  :release => '2008-12-31',
  :summary => 'Gives life to RubyGems-based projects',
  :website => 'http://snk.tuxfamily.org/lib/inochi',
  :require => {
    'rubyforge' => '~> 1',
    'trollop'   => '~> 1.10',
    'yard'      => nil, # alternative to RDoc
    # 'rdoc'          => '~> 2.2',
    # 'darkfish-rdoc' => nil, # good theme for RDoc 2
  }
