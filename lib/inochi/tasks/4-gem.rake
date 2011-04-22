@gem_spec_dst = @project_package_name + '.gemspec'
@gem_spec_src = FileList[
  '{bin,lib,ext}/**/*',
  'LICENSE',
  @man_roff_dst
]

desc 'Build RubyGems package specification.'
task 'gem:spec' => @gem_spec_dst

file @gem_spec_dst => @gem_spec_src do
  Rake::Task[:@ann_nfo_text].invoke
  Rake::Task[:@project_authors_text].invoke

  # ensure that project version matches release notes
  Rake::Task[:@ann_rel_html_body_nodes].invoke

  version_from_notes = @ann_rel_html_title_node.inner_text
  version_from_project = "Version #{@project_module::VERSION} (#{@project_module::RELDATE})"

  unless version_from_notes == version_from_project
    raise 'Project version %s does not match %s in release notes.' %
          [version_from_project.inspect, version_from_notes.inspect]
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
  gem.files       = @gem_spec_src

  @project_module::GEMDEPS.each do |gem_name, gem_version|
    gem.add_dependency gem_name, *Array(gem_version)
  end

  # allow user to configure the gem before it is built
  if logic = @project_config[:gem_spec_logic] and not logic.empty?
    eval logic, binding, "#{PROJECT_CONFIG_FILE} in :gem_spec_logic"
  end

  # emit gemspec
  File.write @gem_spec_dst, gem.to_ruby.
    sub('Gem::Specification.new', 'gemspec = \&').
    sub(/\Z/, "\nsystem 'inochi', *gemspec.files\ngemspec")

  @gem_spec = gem
end

CLOBBER.include @gem_spec_dst

desc 'Build release package for RubyGems.'
task :gem => @project_gem_file

file @project_gem_file => @gem_spec_dst do
  Gem::Builder.new(@gem_spec).build
end

CLOBBER.include @project_gem_file
