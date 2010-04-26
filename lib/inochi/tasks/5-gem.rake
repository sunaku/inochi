desc 'Build release package for RubyGems.'
task :gem do
  Rake::Task[:@project].invoke
  Rake::Task[:@ann_nfo_text].invoke
  Rake::Task[:@project_authors_text].invoke

  gem             = Gem::Specification.new
  gem.name        = @project_package_name
  gem.date        = @project_module::RELDATE
  gem.version     = @project_module::VERSION
  gem.summary     = @project_module::TAGLINE
  gem.description = @ann_nfo_text
  gem.homepage    = @project_module::WEBSITE
  gem.authors     = @project_authors_text.split(/\s*,\s*/)
  gem.executables = FileList['bin/*'].pathmap('%f')

  Rake::Task[:man].invoke
  gem.files = FileList[
    '{bin,lib,ext}/**/*',
    'LICENSE',
    'CREDITS',
    @man_html_dst,
    @man_roff_dst_glob
  ]

  @project_module::DEVTIME.each do |gem_name, gem_version|
    gem.add_development_dependency gem_name, *Array(gem_version)
  end

  @project_module::RUNTIME.each do |gem_name, gem_version|
    gem.add_dependency gem_name, *Array(gem_version)
  end

  # allow user to configure the gem before it is built
  if logic = @project_options[:gem_spec_logic] and not logic.empty?
    eval logic, binding, "#{@project_options_file} in :gem_spec_logic"
  end

  # emit gemspec
  File.write @project_gem_file + 'spec', gem.to_ruby

  # build gem
  Gem::Builder.new(gem).build
end

CLOBBER.include '*.gem', '*.gemspec'
