desc 'Publish a release of this project.'
task :pub => %w[ pub:gem pub:web pub:ann ]

#-----------------------------------------------------------------------------
# RubyGems
#-----------------------------------------------------------------------------

desc 'Publish gem release package to RubyGems.org.'
task 'pub:gem' do
  Rake::Task[:@project].invoke
  Rake::Task[:gem].invoke unless File.exist? @project_gem_file
  sh 'gem', 'push', @project_gem_file
end

#-----------------------------------------------------------------------------
# website
#-----------------------------------------------------------------------------

desc 'Publish help manual, API docs, and RSS feed to project website.'
task 'pub:web' => %w[ man api ann:feed ] do |t|
  Rake::Task[:@project].invoke

  if target = @project_options[:pub_web_target]
    options = @project_options[:pub_web_options]
    sources = [@man_html_dst, @api_dir, @ann_feed_dst,
      @project_options[:pub_web_extras]].compact

    sh ['rsync', options, sources, target].join(' ')
  end
end

#-----------------------------------------------------------------------------
# announcements
#-----------------------------------------------------------------------------

desc 'Announce release on all news outlets.'
task 'pub:ann' => %w[ pub:ann:raa pub:ann:ruby-talk ]

desc 'Announce release on ruby-talk mailing list.'
task 'pub:ann:ruby-talk' do
  site = 'http://ruby-forum.com'

  require 'mechanize'
  browser = Mechanize.new

  # fetch login form
  page = browser.get("#{site}/user/login")
  form = page.forms_with(:action => '/user/login').first or
    raise "cannot find login form on Web page: #{page.uri}"

  # fill login information
  require 'highline'
  highline = HighLine.new

  form['name'] = highline.ask("#{site} username: ")
  form['password'] = highline.ask("#{site} password: ") {|q| q.echo = false }

  # submit login form
  page = form.click_button
  page.at('a[href="/user/logout"]') or
    raise "invalid login for #{site}"

  # make the announcement
  page = browser.get("#{site}/topic/new?forum_id=4")
  form = page.forms_with(:action => '/topic/new#postform').first or
    raise "cannot find post creation form on Web page: #{page.uri}"

  # enable notification by email whenever
  # someone replies to this announcement
  form['post[subscribed_by_author]'] = '1'

  Rake::Task[:@ann_subject].invoke
  form['post[subject]'] = @ann_subject

  Rake::Task[@ann_text_dst].invoke
  form['post[text]'] = File.read(@ann_text_dst)

  # submit the announcement
  page = form.submit

  if error = page.at('.error')
    raise "Announcement to #{site} failed:\n#{error.text}"
  else
    puts "Successfully announced to #{site}:", page.uri
  end
end

desc 'Announce release on RAA (Ruby Application Archive).'
task 'pub:ann:raa' do
  site = 'http://raa.ruby-lang.org'

  Rake::Task[:@project].invoke
  project = @project_package_name

  require 'mechanize'
  browser = Mechanize.new

  # fetch project information form
  page = browser.get("#{site}/update.rhtml?name=#{project}")
  form = page.forms_with(:action => 'regist.rhtml').first or
    raise "cannot find project information form on Web page: #{page.uri}"

  # fill project information
  Rake::Task[:@ann_nfo_text].invoke
  form['description']       = @ann_nfo_text
  form['description_style'] = 'Plain'

  Rake::Task[:@project].invoke
  form['short_description'] = @project_module::TAGLINE
  form['version']           = @project_module::VERSION
  form['url']               = @project_module::WEBSITE

  # fill login information
  require 'highline'
  highline = HighLine.new

  prompt = '%s password for %s project and %s owner: ' %
    [ site, project.inspect, form.owner.inspect ]
  form['pass'] = highline.ask(prompt) {|q| q.echo = false }

  # submit project information
  page = form.submit

  if page.title =~ /error/i
    error = "#{page.at('h2').text} -- #{page.at('p').text.strip}"
    raise "Announcement to #{site} failed:\n#{error}"
  else
    puts "Successfully announced to #{site}."
  end
end
