desc 'Publish a release of this project.'
task :pub => %w[ pub:gem pub:web ]

#-----------------------------------------------------------------------------
# RubyGems
#-----------------------------------------------------------------------------

desc 'Publish gem release package to RubyGems.org.'
task 'pub:gem' do
  Rake::Task[:gem].invoke unless File.exist? @project_gem_file
  sh 'gem', 'push', @project_gem_file
end

#-----------------------------------------------------------------------------
# website
#-----------------------------------------------------------------------------

desc 'Publish help manual, API docs, and RSS feed to project website.'
task 'pub:web' do
  if target = @project_config[:pub_web_target]
    options = @project_config[:pub_web_options]

    sources = [@man_html_dst, @api_dir, @ann_feed_dst,
      @project_config[:pub_web_extras]].compact

    # build the sources if necessary
    sources.each {|s| Rake::Task[s].invoke }

    sh ['rsync', options, sources, target].join(' ')
  end
end
