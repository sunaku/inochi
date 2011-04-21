desc 'Build release package for RubyGems.'
task :gem do
  Rake::Task[:@ann_nfo_text].invoke
  Rake::Task[:@project_authors_text].invoke

  # ensure that project version matches release notes
  Rake::Task[:@ann_rel_html_body_nodes].invoke

  version_from_notes = @ann_rel_html_title_node.inner_text
  version_from_project = "Version #{@project_module::VERSION} (#{@project_module::RELDATE})"

  unless version_from_notes == version_from_project
    raise "Project version #{version_from_project.inspect} does not match "\
      "the #{version_from_notes.inspect} version listed in the release notes."
  end

  # build gemspec
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
    @man_roff_dst
  ]

  @project_module::RUNTIME.each do |gem_name, gem_version|
    gem.add_dependency gem_name, *Array(gem_version)
  end

  # allow user to configure the gem before it is built
  if logic = @project_config[:gem_spec_logic] and not logic.empty?
    eval logic, binding, "#{PROJECT_CONFIG_FILE} in :gem_spec_logic"
  end

  # emit gemspec
  File.write @project_gem_file + 'spec', gem.to_ruby.
    sub('Gem::Specification.new', 'gemspec = \&').
    sub(/\Z/, "\nsystem 'inochi', *gemspec.files\ngemspec")

  # build gem
  Gem::Builder.new(gem).build
end

CLOBBER.include '*.gem', '*.gemspec'
