# -*- encoding: utf-8 -*-

gemspec = Gem::Specification.new do |s|
  s.name = %q{inochi}
  s.version = "6.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Suraj N. Kurapati}]
  s.date = %q{2011-06-29}
  s.description = %q{Inochi is an infrastructure that gives life to open-source [Ruby] projects and helps you document, test, package, publish, announce, and maintain them.}
  s.executables = [%q{inochi}]
  s.files = [%q{bin/inochi}, %q{lib/inochi}, %q{lib/inochi/templates}, %q{lib/inochi/templates/CREDITS.rbs}, %q{lib/inochi/templates/INSTALL.rbs}, %q{lib/inochi/templates/Gemfile.rbs}, %q{lib/inochi/templates/HACKING.rbs}, %q{lib/inochi/templates/LICENSE.rbs}, %q{lib/inochi/templates/MANUAL.rbs}, %q{lib/inochi/templates/inochi.rb.rbs}, %q{lib/inochi/templates/README.rbs}, %q{lib/inochi/templates/test_runner.rbs}, %q{lib/inochi/templates/library.rbs}, %q{lib/inochi/templates/SYNOPSIS.rbs}, %q{lib/inochi/templates/HISTORY.rbs}, %q{lib/inochi/templates/inochi.conf.rbs}, %q{lib/inochi/templates/library_test.rb.rbs}, %q{lib/inochi/templates/USAGE.rbs}, %q{lib/inochi/templates/test_helper.rb.rbs}, %q{lib/inochi/templates/command.rbs}, %q{lib/inochi/templates/BEYOND.rbs}, %q{lib/inochi/generate.rb}, %q{lib/inochi/inochi.rb}, %q{lib/inochi/engine.rb}, %q{lib/inochi/tasks}, %q{lib/inochi/tasks/2-man.css}, %q{lib/inochi/tasks/5-pub.rake}, %q{lib/inochi/tasks/3-ann.rake}, %q{lib/inochi/tasks/1-api.rake}, %q{lib/inochi/tasks/4-gem.rake}, %q{lib/inochi/tasks/2-man.rake}, %q{lib/inochi.rb}, %q{LICENSE}, %q{man/man1/inochi.1}]
  s.homepage = %q{http://snk.tuxfamily.org/lib/inochi/}
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.5}
  s.summary = %q{Gives life to Ruby projects}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rake>, ["< 0.9", ">= 0.8.4"])
      s.add_runtime_dependency(%q<ember>, ["< 1", ">= 0.3.0"])
      s.add_runtime_dependency(%q<nokogiri>, ["< 2", ">= 1.4"])
      s.add_runtime_dependency(%q<yard>, ["< 1", ">= 0.5.8"])
    else
      s.add_dependency(%q<rake>, ["< 0.9", ">= 0.8.4"])
      s.add_dependency(%q<ember>, ["< 1", ">= 0.3.0"])
      s.add_dependency(%q<nokogiri>, ["< 2", ">= 1.4"])
      s.add_dependency(%q<yard>, ["< 1", ">= 0.5.8"])
    end
  else
    s.add_dependency(%q<rake>, ["< 0.9", ">= 0.8.4"])
    s.add_dependency(%q<ember>, ["< 1", ">= 0.3.0"])
    s.add_dependency(%q<nokogiri>, ["< 2", ">= 1.4"])
    s.add_dependency(%q<yard>, ["< 1", ">= 0.5.8"])
  end
end
system 'inochi', *gemspec.files
gemspec
