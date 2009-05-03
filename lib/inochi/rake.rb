#--
# Copyright 2008 Suraj N. Kurapati
# See the LICENSE file for details.
#++

##
# Provides Rake tasks for packaging, publishing, and announcing your project.
#
# * An AUTHORS constant (which has the form "[[name, info]]"
#   where "name" is the name of a copyright holder and "info" is
#   their contact information) is added to the project module.
#
#   Unless this information is supplied via the :authors option,
#   it is automatically extracted from copyright notices in the
#   project license file, where the first copyright notice is
#   expected to correspond to the primary project maintainer.
#
#   Copyright notices must be in the following form:
#
#       Copyright YEAR HOLDER <EMAIL>
#
#   Where HOLDER is the name of the copyright holder, YEAR is the year
#   when the copyright holder first began working on the project, and
#   EMAIL is (optional) the email address of the copyright holder.
#
# ==== Parameters
#
# [project_symbol]
#   Name of the Ruby constant which serves
#   as a namespace for the entire project.
#
# [options]
#   Optional hash of configuration parameters:
#
#   [:test_with]
#     Names of Ruby libraries inside the "inochi/test/"
#     namespace to load before running the test suite.
#
#     The default value is an empty Array.
#
#   [:authors]
#     A list of project authors and their contact information.  This
#     list must have the form "[[name, info]]" where "name" is the name
#     of a project author and "info" is their contact information.
#
#     The default value is automatically extracted from
#     your project's license file (see description above).
#
#   [:license_file]
#     Path (relative to the main project directory which contains the
#     project rakefile) to the file which contains the project license.
#
#     The default value is "LICENSE".
#
#   [:logins_file]
#     Path to the YAML file which contains login
#     information for publishing release announcements.
#
#     The default value is "~/.config/inochi/logins.yaml"
#     where "~" is the path to your home directory.
#
#   [:rubyforge_project]
#     Name of the RubyForge project where
#     release packages will be published.
#
#     The default value is the value of the PROGRAM constant.
#
#   [:rubyforge_section]
#     Name of the RubyForge project's File Release System
#     section where release packages will be published.
#
#     The default value is the value of the :rubyforge_project parameter.
#
#   [:raa_project]
#     Name of the RAA (Ruby Application Archive) entry for this project.
#
#     The default value is the value of the PROGRAM constant.
#
#   [:upload_target]
#     Where to upload the project documentation.
#     See "destination" in the rsync manual.
#
#     The default value is nil.
#
#   [:upload_delete]
#     Delete unknown files at the upload target location?
#
#     The default value is false.
#
#   [:upload_options]
#     Array of command-line arguments to the rsync command.
#
#     The default value is an empty array.
#
#   [:inochi_consumer]
#     Add Inochi as a dependency to the created gem?
#
#     The default value is true.
#
# [gem_config]
#   Optional block that is passed
#   to Gem::specification.new() for
#   additonal gem configuration.
#
def Inochi.rake project_symbol, options = {}, &gem_config
  program_file = first_caller_file
  program_home = File.dirname(program_file)

  # load the project module
    program_name = File.basename(program_home)
    project_libs = File.join('lib', program_name)

    require project_libs
    project_module = fetch_project_module(project_symbol)

  # supply default options
    options[:test_with]         ||= []

    options[:rubyforge_project] ||= program_name
    options[:rubyforge_section] ||= program_name
    options[:raa_project]       ||= program_name

    options[:license_file]      ||= 'LICENSE'
    options[:logins_file]       ||= File.join(
                                      ENV['HOME'] || ENV['USERPROFILE'] || '.',
                                      '.config', 'inochi', 'logins.yaml'
                                    )

    options[:upload_delete]     ||= false
    options[:upload_options]    ||= []

    options[:inochi_consumer]   = true unless options.key? :inochi_consumer

  # add AUTHORS constant to the project module
    copyright_holders = options[:authors] ||
      File.read(options[:license_file]).
      scan(/Copyright.*?\d+\s+(.*)/).flatten.
      map {|s| (s =~ /\s*<(.*?)>/) ? [$`, $1] : [s, ''] }

    project_module.const_set :AUTHORS, copyright_holders

  # establish development gem dependencies
    [Inochi, project_module].uniq.each do |mod|
      mod::DEVELOP.each_pair do |gem_name, version_reqs|
        gem_name     = gem_name.to_s
        version_reqs = Array(version_reqs).compact

        begin
          gem gem_name, *version_reqs
        rescue Gem::Exception => e
          warn e.inspect
        end
      end
    end

  require 'rake/clean'

  hide_rake_task = lambda do |name|
    Rake::Task[name].instance_variable_set :@comment, nil
  end

  # translation
    directory 'lang'

    lang_dump_deps = 'lang'
    lang_dump_file = 'lang/phrases.yaml'

    desc 'Extract language phrases for translation.'
    task 'lang:dump' => lang_dump_file

    file lang_dump_file => lang_dump_deps do
      ENV['dump_lang_phrases'] = '1'
      Rake::Task[:test].invoke
    end

    lang_conv_delim = "\n" * 5

    desc 'Translate extracted language phrases (from=LANGUAGE_CODE).'
    task 'lang:conv' => lang_dump_file do |t|
      require 'babelfish'

      unless
        src_lang = ENV['from'] and
        BabelFish::LANGUAGE_CODES.include? src_lang
      then
        message = ['The "from" parameter must be specified as follows:']

        BabelFish::LANGUAGE_CODES.each do |c|
          n = BabelFish::LANGUAGE_NAMES[c]
          message << "  rake #{t.name} from=#{c}  # from #{n}"
        end

        raise ArgumentError, message.join("\n")
      end

      begin
        require 'yaml'
        phrases = YAML.load_file(lang_dump_file).keys.sort
      rescue
        warn "Could not load phrases from #{lang_dump_file.inspect}"
        raise
      end

      src_lang_name = BabelFish::LANGUAGE_NAMES[src_lang]

      BabelFish::LANGUAGE_PAIRS[src_lang].each do |dst_lang|
        dst_file      = "lang/#{dst_lang}.yaml"
        dst_lang_name = BabelFish::LANGUAGE_NAMES[dst_lang]

        puts "Translating phrases from #{src_lang_name} into #{dst_lang_name} as #{dst_file.inspect}"

        translations = BabelFish.translate(
          phrases.join(lang_conv_delim), src_lang, dst_lang
        ).split(lang_conv_delim)

        File.open(dst_file, 'w') do |f|
          f.puts "# #{dst_lang} (#{dst_lang_name})"

          phrases.zip(translations).each do |a, b|
            f.puts "#{a}: #{b}"
          end
        end
      end
    end

  # testing
    test_runner = lambda do |interpreter|
      require 'tempfile'
      script = Tempfile.new($$).path # will be deleted on program exit

      libs = [program_name] + # load the project-under-test's library FIRST!
        Array(options[:test_with]).map {|lib| "inochi/test/#{lib}" }

      File.write script, %{
        # the "-I." option lets us load helper libraries inside
        # the test suite via "test/PROJECT_NAME/LIBRARY_NAME"
        $LOAD_PATH.unshift '.', 'lib'

        #{libs.inspect}.each do |lib|
          require lib
        end

        # set title of test suite
        $0 = #{project_module.to_s.inspect}

        # dump language phrases *after* exercising all code (and
        # thereby populating the phrases cache) in the project
        at_exit do
          if ENV['dump_lang_phrases'] == '1'
            file = #{File.expand_path(lang_dump_file).inspect}
            list = eval(#{project_symbol.to_s.inspect})::PHRASES.phrases
            data = list.map {|s| s + ':' }.join("\n")

            File.write file, data

            puts "Extracted \#{list.length} language phrases into \#{file.inspect}"
          end
        end

        Dir['test/**/*.rb'].sort.each do |test|
          unit = test.sub('test/', 'lib/')

          if File.exist? unit
            # strip file extension because require()
            # does not normalize its input and it
            # will think that the two paths (with &
            # without file extension) are different
            unit_path = unit.sub(/\.rb$/, '').sub('lib/', '')
            test_path = test.sub(/\.rb$/, '')

            require unit_path
            require test_path
          else
            warn "Skipped test \#{test.inspect} because it lacks a corresponding \#{unit.inspect} unit."
          end
        end
      }

      command = [interpreter.to_s]

      if interpreter == :rcov
        command.push '--output', 'cov'

        # omit internals from coverage analysis
        command.push '--exclude-only', script
        command.push '--exclude', Inochi::INSTALL

        require 'rbconfig'
        ruby_internals = File.dirname(Config::CONFIG['rubylibdir'])
        command.push '--exclude', /^#{Regexp.quote ruby_internals}/.to_s

        # show results summary after execution
        command.push '-T'
      else
        # enable Ruby warnings during execution
        command << '-w'
      end

      command << script

      require 'shellwords'
      command.concat Shellwords.shellwords(ENV['opts'].to_s)

      sh(*command)
    end

    desc 'Run tests.'
    task :test do
      test_runner.call :ruby
    end

    desc 'Run tests with code coverage analysis.'
    task 'test:cov' do
      test_runner.call :rcov
    end

    CLEAN.include 'cov'

    desc 'Run tests with multiple Ruby versions.'
    task 'test:ruby' do
      test_runner.call :multiruby
    end

    desc 'Report code quality statistics.'
    task 'lint' do
      separator = '-' * 80

      linter = lambda do |*command|
        name = command.first

        puts "\n\n", separator, name, separator
        system(*command)
      end

      ruby_files = Dir['**/*.rb']

      linter.call 'sloccount', '.'
      linter.call 'flay' # operates on all .rb & .erb files by default
      linter.call 'reek', *ruby_files
      linter.call 'roodi', *ruby_files
      linter.call 'ruby_diff', *ruby_files
    end

  # documentation
    desc 'Build all documentation.'
    task :doc => %w[ doc:api doc:man ]

    # user manual
      doc_man_src = 'doc/index.erb'
      doc_man_dst = 'doc/index.xhtml'
      doc_man_deps = FileList['doc/*.erb']

      doc_man_doc = nil
      task :doc_man_doc => doc_man_src do
        unless doc_man_doc
          require 'erbook' unless defined? ERBook

          doc_man_txt = File.read(doc_man_src)
          doc_man_doc = ERBook::Document.new(:xhtml, doc_man_txt, doc_man_src, :unindent => true)
        end
      end

      desc 'Build the user manual.'
      task 'doc:man' => doc_man_dst

      file doc_man_dst => doc_man_deps do
        Rake::Task[:doc_man_doc].invoke
        File.write doc_man_dst, doc_man_doc
      end

      CLOBBER.include doc_man_dst

    # API reference
      doc_api_dst = 'doc/api'

      desc 'Build API reference.'
      task 'doc:api' => 'doc:api:rdoc'

      namespace :doc do
        namespace :api do
          require 'sdoc'
          require 'rake/rdoctask'

          Rake::RDocTask.new do |t|
            t.rdoc_dir = doc_api_dst
            t.template = 'direct' # lighter template used on railsapi.com
            t.options.push '--fmt', 'shtml' # explictly set shtml generator
            t.rdoc_files.include '[A-Z]*', 'lib/**/*.rb', 'ext/**/*.{rb,c*}'

            # regen when sources change
            task t.name => t.rdoc_files

            t.main = options[:license_file]
            task t.name => t.main
          end

          %w[rdoc clobber_rdoc rerdoc].each do |inner|
            hide_rake_task["doc:api:#{inner}"]
          end
        end
      end

      CLOBBER.include doc_api_dst

  # announcements
    desc 'Build all release announcements.'
    task :ann => %w[ ann:feed ann:html ann:text ann:mail ]

    # it has long been a tradition to use an "[ANN]" prefix
    # when announcing things on the ruby-talk mailing list
    ann_prefix = '[ANN] '
    ann_subject = ann_prefix + project_module::DISPLAY
    ann_project = ann_prefix + project_module::PROJECT

    # fetch the project summary from user manual
      ann_nfo_doc = nil
      task :ann_nfo_doc => :doc_man_doc do
        ann_nfo_doc = $project_summary_node
      end

    # fetch release notes from user manual
      ann_rel_doc = nil
      task :ann_rel_doc => :doc_man_doc do
        unless ann_rel_doc
          if parent = $project_history_node
            if child = parent.children.first
              ann_rel_doc = child
            else
              raise 'The "project_history" node in the user manual lacks child nodes.'
            end
          else
            raise 'The user manual lacks a "project_history" node.'
          end
        end
      end

    # build release notes in HTML and plain text
      # converts the given HTML into plain text.  we do this using
      # lynx because (1) it outputs a list of all hyperlinks used
      # in the HTML document and (2) it runs on all major platforms
      convert_html_to_text = lambda do |html|
        require 'tempfile'

        begin
          # lynx's -dump option requires a .html file
          tmp_file = Tempfile.new(Inochi::PROGRAM).path + '.html'

          File.write tmp_file, html
          text = `lynx -dump #{tmp_file} -width 70`
        ensure
          File.delete tmp_file
        end

        # improve readability of list items
        # by adding a blank line between them
        text.gsub! %r{(\r?\n)( +\* \S)}, '\1\1\2'

        text
      end

      # binds relative addresses in the given HTML to the project docsite
      resolve_html_links = lambda do |html|
        # resolve relative URLs into absolute URLs
        # see http://en.wikipedia.org/wiki/URI_scheme#Generic_syntax
        require 'addressable/uri'
        uri = Addressable::URI.parse(project_module::DOCSITE)
        doc_url = uri.to_s
        dir_url = uri.path =~ %r{/$|^$} ? doc_url : File.dirname(doc_url)

        html.to_s.gsub %r{(href=|src=)(.)(.*?)(\2)} do |match|
          a, b = $1 + $2, $3.to_s << $4

          case $3
          when %r{^[[:alpha:]][[:alnum:]\+\.\-]*://} # already absolute
            match

          when /^#/
            a << File.join(doc_url, b)

          else
            a << File.join(dir_url, b)
          end
        end
      end

      ann_html = nil
      task :ann_html => [:doc_man_doc, :ann_nfo_doc, :ann_rel_doc] do
        unless ann_html
          ann_html = %{
            <center>
              <h1>#{project_module::DISPLAY}</h1>
              <p>#{project_module::TAGLINE}</p>
              <p>#{project_module::WEBSITE}</p>
            </center>
            #{ann_nfo_doc}
            #{ann_rel_doc}
          }

          # remove heading navigation menus
          ann_html.gsub! %r{<div class="nav"[^>]*>(.*?)</div>}, ''

          # remove latex-style heading numbers
          ann_html.gsub! %r"(<(h\d)[^>]*>).+?(?:&nbsp;){2}(.+?)(</\2>)"m, '\1\3\4'

          ann_html = resolve_html_links[ann_html]
        end
      end

      ann_text = nil
      task :ann_text => :ann_html do
        unless ann_text
          ann_text = convert_html_to_text[ann_html]
        end
      end

      ann_nfo_text = nil
      task :ann_nfo_text => :ann_nfo_doc do
        unless ann_nfo_text
          ann_nfo_html = resolve_html_links[ann_nfo_doc]
          ann_nfo_text = convert_html_to_text[ann_nfo_html]
        end
      end

    # HTML
      ann_html_dst = 'ANN.html'

      desc "Build HTML announcement: #{ann_html_dst}"
      task 'ann:html' => ann_html_dst

      file ann_html_dst => doc_man_deps do
        Rake::Task[:ann_html].invoke
        File.write ann_html_dst, ann_html
      end

      CLEAN.include ann_html_dst

    # RSS feed
      ann_feed_dst = 'doc/ann.xml'

      desc "Build RSS announcement: #{ann_feed_dst}"
      task 'ann:feed' => ann_feed_dst

      file ann_feed_dst => doc_man_deps do
        require 'time'
        require 'rss/maker'

        feed = RSS::Maker.make('2.0') do |feed|
          feed.channel.title       = ann_project
          feed.channel.link        = project_module::WEBSITE
          feed.channel.description = project_module::TAGLINE

          Rake::Task[:ann_rel_doc].invoke
          Rake::Task[:ann_html].invoke

          item             = feed.items.new_item
          item.title       = ann_rel_doc.title
          item.link        = project_module::DOCSITE + '#' + ann_rel_doc.here_frag
          item.date        = Time.parse(item.title)
          item.description = ann_html
        end

        File.write ann_feed_dst, feed
      end

      CLOBBER.include ann_feed_dst

    # plain text
      ann_text_dst = 'ANN.txt'

      desc "Build plain text announcement: #{ann_text_dst}"
      task 'ann:text' => ann_text_dst

      file ann_text_dst => doc_man_deps do
        Rake::Task[:ann_text].invoke
        File.write ann_text_dst, ann_text
      end

      CLEAN.include ann_text_dst

    # e-mail
      ann_mail_dst = 'ANN.eml'

      desc "Build e-mail announcement: #{ann_mail_dst}"
      task 'ann:mail' => ann_mail_dst

      file ann_mail_dst => doc_man_deps do
        File.open ann_mail_dst, 'w' do |f|
          require 'time'
          f.puts "Date: #{Time.now.rfc822}"

          f.puts 'To: ruby-talk@ruby-lang.org'
          f.puts 'From: "%s" <%s>' % project_module::AUTHORS.first
          f.puts "Subject: #{ann_subject}"

          Rake::Task[:ann_text].invoke
          f.puts '', ann_text
        end
      end

      CLEAN.include ann_mail_dst

  # packaging
    desc 'Build a release.'
    task :gem => [:clobber, :doc] do
      sh $0, 'gem:package'
    end
    CLEAN.include 'pkg'

    # ruby gem
      require 'rake/gempackagetask'

      gem_spec = Gem::Specification.new do |gem|
        authors = project_module::AUTHORS

        if author = authors.first
          gem.author, gem.email = author
        end

        if authors.length > 1
          gem.authors = authors.map {|name, mail| name }
        end

        gem.rubyforge_project = options[:rubyforge_project]

        # XXX: In theory, `gem.name` should be assigned to
        #      ::PROJECT instead of ::PROGRAM
        #
        #      In practice, PROJECT may contain non-word
        #      characters and may also contain a mixture
        #      of lowercase and uppercase letters.
        #
        #      This makes it difficult for people to
        #      install the project gem because they must
        #      remember the exact spelling used in
        #      `gem.name` when running `gem install ____`.
        #
        #      For example, consider the "RedCloth" gem.
        #
        gem.name        = project_module::PROGRAM

        gem.version     = project_module::VERSION
        gem.summary     = project_module::TAGLINE
        gem.description = gem.summary
        gem.homepage    = project_module::WEBSITE
        gem.files       = FileList['**/*'].exclude('_darcs') - CLEAN
        gem.has_rdoc    = true

        executable      = project_module::PROGRAM
        executable_path = File.join(gem.bindir, executable)
        gem.executables = executable if File.exist? executable_path

        project_module::DEVELOP.each_pair do |gem_name, version_reqs|
          version_reqs = Array(version_reqs).compact
          gem.add_development_dependency gem_name, *version_reqs
        end

        project_module::REQUIRE.each_pair do |gem_name, version_reqs|
          version_reqs = Array(version_reqs).compact
          gem.add_dependency gem_name, *version_reqs
        end

        unless project_module == Inochi
          gem.add_development_dependency Inochi::PROGRAM, Inochi::VERSION.requirement

          if options[:inochi_consumer]
            gem.add_dependency Inochi::PROGRAM, Inochi::VERSION.requirement
          end
        end

        # additional configuration is done by user
        yield gem if gem_config
      end

      namespace :gem do
        Rake::GemPackageTask.new(gem_spec).define

        %w[gem package repackage clobber_package].each do |t|
          hide_rake_task.call "gem:#{t}"
        end
      end

      task :clobber => "gem:clobber_package"

  # releasing
    desc 'Publish a release.'
    task 'pub' => %w[ pub:gem pub:doc pub:ann ]

    # connect to RubyForge services
      pub_forge = nil
      pub_forge_project = options[:rubyforge_project]
      pub_forge_section = options[:rubyforge_section]

      task :pub_forge do
        require 'rubyforge'
        pub_forge = RubyForge.new
        pub_forge.configure('release_date' => project_module::RELEASE)

        unless pub_forge.autoconfig['group_ids'].key? pub_forge_project
          raise "The #{pub_forge_project.inspect} project was not recognized by the RubyForge client.  Either specify a different RubyForge project by passing the :rubyforge_project option to Inochi.rake(), or ensure that the client is configured correctly (see `rubyforge --help` for help) and try again."
        end

        pub_forge.login
      end

    # documentation
      desc 'Publish documentation to project website.'
      task 'pub:doc' => [:doc, 'ann:feed'] do
        target = options[:upload_target]

        unless target
          require 'addressable/uri'
          docsite = Addressable::URI.parse(project_module::DOCSITE)

          # provide uploading capability to websites hosted on RubyForge
          if docsite.host.include? '.rubyforge.org'
            target = "#{pub_forge.userconfig['username']}@rubyforge.org:#{File.join '/var/www/gforge-projects', options[:rubyforge_project], docsite.path}"
          end
        end

        if target
          cmd = ['rsync', '-auvz', 'doc/', "#{target}/"]
          cmd.push '--delete' if options[:upload_delete]
          cmd.concat options[:upload_options]

          p cmd
          sh(*cmd)
        end
      end

    # announcement
      desc 'Publish all announcements.'
      task 'pub:ann' => %w[ pub:ann:forge pub:ann:raa pub:ann:talk ]

      # login information
        ann_logins_file = options[:logins_file]
        ann_logins = nil

        task :ann_logins do
          ann_logins = begin
            require 'yaml'
            YAML.load_file ann_logins_file
          rescue => e
            warn "Could not read login information from #{ann_logins_file.inspect}:"
            warn e
            warn "** You will NOT be able to publish release announcements! **"
            {}
          end
        end

      desc 'Announce to RubyForge news.'
      task 'pub:ann:forge' => :pub_forge do
        puts 'Announcing to RubyForge news...'

        project = options[:rubyforge_project]

        if group_id = pub_forge.autoconfig['group_ids'][project]
          # check if this release was already announced
            require 'mechanize'
            www = WWW::Mechanize.new
            page = www.get "http://rubyforge.org/news/?group_id=#{group_id}"

            posts = (page/'//a[starts-with(./@href, "/forum/forum.php?forum_id=")]/text()').map {|e| e.to_s.gsub("\302\240", '').strip }

            already_announced = posts.include? ann_subject

          if already_announced
            warn 'This release was already announced to RubyForge news, so I will NOT announce it there again.'
          else
            # make the announcement
            Rake::Task[:ann_text].invoke
            pub_forge.post_news project, ann_subject, ann_text

            puts 'Successfully announced to RubyForge news:', page.uri
          end
        else
          raise "Could not determine the group_id of the #{project.inspect} RubyForge project.  Run `rubyforge config` and try again."
        end
      end

      desc 'Announce to ruby-talk mailing list.'
      task 'pub:ann:talk' => :ann_logins do
        puts 'Announcing to ruby-talk mailing list...'

        host = 'http://ruby-forum.com'
        ruby_talk = 4 # ruby-talk forum ID

        require 'mechanize'
        www = WWW::Mechanize.new

        # check if this release was already announced
        already_announced =
          begin
            page = www.get "#{host}/forum/#{ruby_talk}", :filter => %{"#{ann_subject}"}

            posts = (page/'//div[@class="forum"]//a[starts-with(./@href, "/topic/")]/text()').map {|e| e.to_s.strip }
            posts.include? ann_subject
          rescue
            false
          end

        if already_announced
          warn 'This release was already announced to the ruby-talk mailing list, so I will NOT announce it there again.'
        else
          # log in to RubyForum
          page = www.get "#{host}/user/login"
          form = page.forms.first

          if login = ann_logins['www.ruby-forum.com']
            form['name'] = login['user']
            form['password'] = login['pass']
          end

          page = form.click_button # use the first submit button

          if (page/'//a[@href="/user/logout"]').empty?
            warn "Could not log in to RubyForum using the login information in #{ann_logins_file.inspect}, so I can NOT announce this release to the ruby-talk mailing list."
          else
            # make the announcement
            page = www.get "#{host}/topic/new?forum_id=#{ruby_talk}"
            form = page.forms.first

            Rake::Task[:ann_text].invoke
            form['post[subject]'] = ann_subject
            form['post[text]'] = ann_text

            # enable email notification
            form.field_with(:name => 'post[subscribed_by_author]').value = '1'

            page = form.submit

            errors = [page/'//div[@class="error"]/text()'].flatten
            if errors.empty?
              puts 'Successfully announced to ruby-talk mailing list:', page.uri
            else
              warn 'Could not announce to ruby-talk mailing list:'
              warn errors.join("\n")
            end
          end
        end
      end

      desc 'Announce to RAA (Ruby Application Archive).'
      task 'pub:ann:raa' => :ann_logins do
        puts 'Announcing to RAA (Ruby Application Archive)...'

        show_page_error = lambda do |page, message|
          warn "#{message}, so I can NOT announce this release to RAA:"
          warn "#{(page/'h2').text} -- #{(page/'p').first.text.strip}"
        end

        resource = "#{options[:raa_project].inspect} project entry on RAA"

        require 'mechanize'
        www = WWW::Mechanize.new
        page = www.get "http://raa.ruby-lang.org/update.rhtml?name=#{options[:raa_project]}"

        if form = page.forms[1]
          resource << " (owned by #{form.owner.inspect})"

          Rake::Task[:ann_nfo_text].invoke
          form['description']       = ann_nfo_text
          form['description_style'] = 'Pre-formatted'
          form['short_description'] = project_module::TAGLINE
          form['version']           = project_module::VERSION
          form['url']               = project_module::WEBSITE
          form['pass']              = ann_logins['raa.ruby-lang.org']['pass']

          page = form.submit

          if page.title =~ /error/i
            show_page_error[page, "Could not update #{resource}"]
          else
            puts 'Successfully announced to RAA (Ruby Application Archive).'
          end
        else
          show_page_error[page, "Could not access #{resource}"]
        end
      end

    # release packages
      desc 'Publish release packages to RubyForge.'
      task 'pub:gem' => :pub_forge do
        # check if this release was already published
        version = project_module::VERSION
        packages = pub_forge.autoconfig['release_ids'][pub_forge_section]

        if packages and packages.key? version
          warn "The release packages were already published, so I will NOT publish them again."
        else
          # create the FRS package section
          unless pub_forge.autoconfig['package_ids'].key? pub_forge_section
            pub_forge.create_package pub_forge_project, pub_forge_section
          end

          # publish the package to the section
          uploader = lambda do |command, *files|
            pub_forge.__send__ command, pub_forge_project, pub_forge_section, version, *files
          end

          Rake::Task[:gem].invoke
          packages = Dir['pkg/*.[a-z]*']

          unless packages.empty?
            # NOTE: use the 'add_release' command ONLY for the first
            #       file because it creates a new sub-section on the
            #       RubyForge download page; we do not want one package
            #       per sub-section on the RubyForge download page!
            #
            uploader[:add_release, packages.shift]

            unless packages.empty?
              uploader[:add_file, *packages]
            end

            puts "Successfully published release packages to RubyForge."
          end
        end
      end
end
