# -*- encoding: utf-8 -*-

gemspec = Gem::Specification.new do |s|
  s.name = %q{inochi}
  s.version = "5.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Suraj N. Kurapati"]
  s.date = %q{2010-08-14}
  s.default_executable = %q{inochi}
  s.description = %q{Inochi is an infrastructure that helps you create, test, document, package, publish, and announce your [Ruby] projects.}
  s.executables = ["inochi"]
  s.files = ["bin/inochi", "lib/inochi", "lib/inochi/templates", "lib/inochi/templates/CREDITS.rbs", "lib/inochi/templates/INSTALL.rbs", "lib/inochi/templates/Gemfile.rbs", "lib/inochi/templates/HACKING.rbs", "lib/inochi/templates/LICENSE.rbs", "lib/inochi/templates/MANUAL.rbs", "lib/inochi/templates/inochi.rb.rbs", "lib/inochi/templates/README.rbs", "lib/inochi/templates/test_runner.rbs", "lib/inochi/templates/library.rbs", "lib/inochi/templates/SYNOPSIS.rbs", "lib/inochi/templates/HISTORY.rbs", "lib/inochi/templates/inochi.conf.rbs", "lib/inochi/templates/library_test.rb.rbs", "lib/inochi/templates/USAGE.rbs", "lib/inochi/templates/test_helper.rb.rbs", "lib/inochi/templates/command.rbs", "lib/inochi/templates/BEYOND.rbs", "lib/inochi/generate.rb", "lib/inochi/inochi.rb", "lib/inochi/engine.rb", "lib/inochi/tasks", "lib/inochi/tasks/2-man.css", "lib/inochi/tasks/5-pub.rake", "lib/inochi/tasks/3-ann.rake", "lib/inochi/tasks/1-api.rake", "lib/inochi/tasks/4-gem.rake", "lib/inochi/tasks/2-man.rake", "lib/inochi.rb", "LICENSE", "man/man1/inochi.1"]
  s.homepage = %q{http://snk.tuxfamily.org/lib/inochi/}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Gives life to Ruby projects}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ember>, ["< 1", ">= 0.3.0"])
      s.add_runtime_dependency(%q<highline>, ["< 2", ">= 1.5"])
      s.add_runtime_dependency(%q<mechanize>, ["< 2", ">= 1"])
      s.add_runtime_dependency(%q<nokogiri>, ["< 2", ">= 1.4"])
      s.add_runtime_dependency(%q<rake>, ["< 1", ">= 0.8.4"])
      s.add_runtime_dependency(%q<yard>, ["< 1", ">= 0.5.8"])
    else
      s.add_dependency(%q<ember>, ["< 1", ">= 0.3.0"])
      s.add_dependency(%q<highline>, ["< 2", ">= 1.5"])
      s.add_dependency(%q<mechanize>, ["< 2", ">= 1"])
      s.add_dependency(%q<nokogiri>, ["< 2", ">= 1.4"])
      s.add_dependency(%q<rake>, ["< 1", ">= 0.8.4"])
      s.add_dependency(%q<yard>, ["< 1", ">= 0.5.8"])
    end
  else
    s.add_dependency(%q<ember>, ["< 1", ">= 0.3.0"])
    s.add_dependency(%q<highline>, ["< 2", ">= 1.5"])
    s.add_dependency(%q<mechanize>, ["< 2", ">= 1"])
    s.add_dependency(%q<nokogiri>, ["< 2", ">= 1.4"])
    s.add_dependency(%q<rake>, ["< 1", ">= 0.8.4"])
    s.add_dependency(%q<yard>, ["< 1", ">= 0.5.8"])
  end
end
system 'inochi', *gemspec.files
gemspec
