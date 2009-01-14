require 'rubygems'

module Inochi
class << self
  ##
  # Establishes your project in Ruby's runtime environment by defining
  # the project module (which serves as a namespace for all code in the
  # project) and providing a common configuration for the project module:
  #
  # * Adds the project lib/ directory to the Ruby load path.
  #
  # * Defines the INOCHI constant in the project module.  This constant
  #   contains the effective configuration parameters (@see project_config).
  #
  # * Defines all configuration parameters as constants in the project module.
  #
  # This method must be invoked from immediately within (that is, not from
  # within any of its descendant directories) the project lib/ directory.
  # Ideally, this method would be invoked from the main project library.
  #
  # @param [Symbol] project_symbol
  #   Name of the Ruby constant which serves
  #   as a namespace for the entire project.
  #
  # @param [Hash] project_config
  #   Project configuration parameters:
  #
  #   [String] :project =>
  #     Name of the project.
  #
  #     The default value is the value of the project_symbol parameter.
  #
  #   [String] :tagline =>
  #     An enticing, single line description of the project.
  #
  #     The default value is an empty string.
  #
  #   [String] :website =>
  #     URL of the published project website.
  #
  #     The default value is an empty string.
  #
  #   [String] :docsite =>
  #     URL of the published user manual.
  #
  #     The default value is the same value as the :website parameter.
  #
  #   [String] :program =>
  #     Name of the main project executable.
  #
  #     The default value is the value of the :project parameter in lowercase.
  #
  #   [String] :version =>
  #     Version of the project.
  #
  #     The default value is "0.0.0".
  #
  #   [String] :release =>
  #     Date when this version was released.
  #
  #     The default value is the current time.
  #
  #   [String] :display =>
  #     How the project name should be displayed.
  #
  #     The default value is the project name and version together.
  #
  #   [String] :install =>
  #     Path to the directory which contains the project.
  #
  #     The default value is one directory above the parent
  #     directory of the file from which this method was called.
  #
  #   [Hash] :require =>
  #     The names and version constraints of ruby gems required by
  #     this project.  This information must be expressed as follows:
  #
  #     * Each hash key must be the name of a ruby gem.
  #
  #     * Each hash value must be either +nil+, a single version number
  #       requirement string (see Gem::Requirement) or an Array thereof.
  #
  #     The default value is an empty Hash.
  #
  # @return [Module] The newly configured project module.
  #
  def init project_symbol, project_config = {}
    project_module = fetch_project_module(project_symbol)

    # this method is not re-entrant
      @already_seen ||= []
      return project_module if @already_seen.include? project_module
      @already_seen << project_module

    # put project on Ruby load path
      project_file = File.expand_path(first_caller_file)
      project_libs = File.dirname(project_file)
      $LOAD_PATH.unshift project_libs

    # supply configuration defaults
      project_config[:project] ||= project_symbol.to_s
      project_config[:tagline] ||= ''
      project_config[:version] ||= '0.0.0'
      project_config[:release] ||= Time.now.strftime('%F')
      project_config[:website] ||= ''
      project_config[:docsite] ||= project_config[:website]
      project_config[:display] ||= "#{project_config[:project]} #{project_config[:version]}"
      project_config[:program] ||= calc_program_name(project_symbol)
      project_config[:install] ||= File.dirname(project_libs)
      project_config[:require] ||= {}

    # establish gem version dependencies and
    # sanitize the values while we're at it
      src = project_config[:require].dup
      dst = project_config[:require].clear

      src.each_pair do |gem_name, version_reqs|
        gem_name     = gem_name.to_s
        version_reqs = [version_reqs].flatten.compact

        dst[gem_name] = version_reqs
        gem gem_name, *version_reqs
      end

    # make configuration parameters available as constants
      project_config[:inochi] = project_config

      project_config.each_pair do |param, value|
        project_module.const_set param.to_s.upcase, value
      end

    project_module
  end

  ##
  # Provides a common configuration for the main project executable:
  #
  # * The program description (the sequence of non-blank lines at the
  #   top of the file in which this method is invoked) is properly
  #   formatted and displayed at the top of program's help information.
  #
  # * The program version information is fetched from the project module
  #   and formatted in YAML fashion for easy consumption by other tools.
  #
  # * A list of command-line options is displayed at
  #   the bottom of the program's help information.
  #
  # @param [Symbol] project_symbol
  #   Name of the Ruby constant which serves
  #   as a namespace for the entire project.
  #
  # @param trollop_args
  #   Optional arguments for Trollop::options().
  #
  # @param trollop_config
  #   Optional block argument for Trollop::options().
  #
  # @return The result of Trollop::options().
  #
  def main project_symbol, *trollop_args, &trollop_config
    program_file = first_caller_file

    # load the project module
      program_name = calc_program_name(project_symbol)

      require File.join(File.dirname(program_file), '..', 'lib', program_name)
      project_module = fetch_project_module(project_symbol)

    # parse command-line options
      require 'trollop'

      Trollop.options(*trollop_args) do
        # show project description
        text "#{project_module::PROJECT} - #{project_module::TAGLINE}"
        text ''

        # show program description
        text File.read(program_file)[/\A.*?^$\n/m]. # grab the header
             gsub(/^# ?/, ''). # strip the comment markers
             sub(/\A!.*?\n/, '').lstrip # omit the shebang line
        text ''

        instance_eval(&trollop_config) if trollop_config

        # show version information
        version %w[PROJECT VERSION RELEASE WEBSITE INSTALL].map {|c|
          "#{c.downcase}: #{project_module.const_get c}"
        }.join("\n")
      end
  end

  ##
  # Provides Rake tasks for packaging, publishing, and announcing your project.
  #
  # * An AUTHORS constant (which has the form "[[name, info]]"
  #   where "name" is the name of a copyright holder and "info" is
  #   their contact information) is added to the project module.
  #
  #   This information is extracted from copyright notices in
  #   the project license file.  NOTE that the first copyright
  #   notice must correspond to the primary project maintainer.
  #
  #   Copyright notices must be in the following form:
  #
  #       Copyright YEAR HOLDER <EMAIL>
  #
  #   Where HOLDER is the name of the copyright holder, YEAR is the year
  #   when the copyright holder first began working on the project, and
  #   EMAIL is (optional) the email address of the copyright holder.
  #
  # @param [Symbol] project_symbol
  #   Name of the Ruby constant which serves
  #   as a namespace for the entire project.
  #
  # @param [Hash] options
  #   Additional method parameters, which are all optional:
  #
  #   [String] :license_file =>
  #     Path (relative to the main project directory which contains the
  #     project Rakefile) to the file which contains the project license.
  #
  #     The default value is "LICENSE".
  #
  #   [String] :rubyforge_project =>
  #     Name of the RubyForge project where
  #     release packages will be published.
  #
  #     The default value is the value of the PROGRAM constant.
  #
  #   [String] :rubyforge_section =>
  #     Name of the RubyForge project's File Release System
  #     section where release packages will be published.
  #
  #     The default value is the value of the :rubyforge_project parameter.
  #
  #   [String] :raa_project =>
  #     Name of the RAA (Ruby Application Archive) entry for this project.
  #
  #     The default value is the value of the PROGRAM constant.
  #
  #   [String] :upload_target =>
  #     Where to upload the project documentation.
  #     See "destination" in the rsync manual.
  #
  #     The default value is nil.
  #
  #   [String] :upload_delete =>
  #     Delete unknown files at the upload target location?
  #
  #     The default value is false.
  #
  #   [Array] :upload_options =>
  #     Additional command-line arguments to the rsync command.
  #
  #     The default value is an empty array.
  #
  # @param gem_config
  #   Block that is passed to Gem::specification.new()
  #   for additonal gem configuration.
  #
  # @yieldparam [Gem::Specification] gem_spec the gem specification
  #
  def rake project_symbol, options = {}, &gem_config
    # load the project module
      program_name = calc_program_name(project_symbol)

      require File.join('lib', program_name)
      project_module = fetch_project_module(project_symbol)

    # supply default options
      options[:rubyforge_project] ||= program_name
      options[:rubyforge_section] ||= program_name
      options[:raa_project] ||= program_name
      options[:license_file] ||= 'LICENSE'
      options[:upload_delete] ||= false
      options[:upload_options] ||= []

    # add AUTHORS constant to the project module
      license = File.read(options[:license_file])

      copyright_holders =
        license.scan(/Copyright.*?\d+\s+(.*)/).flatten.
        map {|s| (s =~ /\s*<(.*?)>/) ? [$`, $1] : [s, ''] }

      project_module.const_set :AUTHORS, copyright_holders

    require 'rake/clean'

    hide_rake_task = lambda do |name|
      Rake::Task[name].instance_variable_set :@comment, nil
    end

    # documentation
      desc 'Build all documentation.'
      task :doc => %w[ doc:api doc:man ann:feed ]

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
        task 'doc:api' => doc_api_dst

        require 'yard'
        YARD::Rake::YardocTask.new doc_api_dst do |t|
          t.options.push '--protected',
            '--output-dir', doc_api_dst,
            '--readme', options[:license_file]

          task doc_api_dst => options[:license_file]
        end

        hide_rake_task[doc_api_dst]

        CLEAN.include '.yardoc'
        CLOBBER.include doc_api_dst

    # announcments
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

          # improve readability of list items that span multiple
          # lines by adding a blank line between such items
          text.gsub! %r{^( *[^\*\s].*)(\r?\n)( *\* \S)}, '\1\2\2\3'

          text
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

            # resolve relative URLs into absolute URLs
            # see http://en.wikipedia.org/wiki/URI_scheme#Generic_syntax
            require 'uri'
            uri = URI.parse(project_module::DOCSITE)
            doc_url = uri.to_s
            dir_url = uri.path =~ %r{/$|^$} ? doc_url : File.dirname(doc_url)

            ann_html.gsub! %r{(href=|src=)(.)(.*?)(\2)} do |match|
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
            ann_nfo_text = convert_html_to_text[ann_nfo_doc]
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
          require 'tmail'
          mail         = TMail::Mail.new
          mail.to      = 'ruby-talk@ruby-lang.org'
          mail.from    = '%s <%s>' % project_module::AUTHORS.first
          mail.subject = ann_subject
          mail.date    = Time.now

          Rake::Task[:ann_text].invoke
          mail.body = ann_text

          File.write ann_mail_dst, mail
        end

        CLEAN.include ann_mail_dst

    # packaging
      desc 'Build a release.'
      task :pak => [:clobber, :doc] do
        sh $0, 'package'
      end
      CLEAN.include 'pkg'

      # ruby gem
        require 'rake/gempackagetask'

        gem = Gem::Specification.new do |gem|
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
          gem.executables = project_module::PROGRAM
          gem.has_rdoc    = true

          unless project_module == Inochi
            gem.add_dependency 'inochi', Inochi::VERSION
          end

          project_module::REQUIRE.each_pair do |gem_name, version_reqs|
            gem.add_dependency gem_name, *version_reqs
          end

          # additional configuration is done by user
          yield gem if gem_config
        end

        Rake::GemPackageTask.new(gem).define

        # XXX: hide the tasks defined by the above gem packaging library
        %w[gem package repackage clobber_package].each {|t| hide_rake_task[t] }

    # releasing
      desc 'Publish a new release.'
      task 'pub' => %w[ pub:pak pub:doc pub:ann ]

      # connect to RubyForge services
        pub_rubyforge = nil

        task :pub_rubyforge do
          require 'rubyforge'

          pub_rubyforge = RubyForge.new
          pub_rubyforge.configure 'release_date' => project_module::RELEASE

          pub_rubyforge.login
        end

      # documentation
        desc 'Publish documentation to project website.'
        task 'pub:doc' => [:doc, :pub_rubyforge] do
          target = options[:upload_target]

          unless target
            require 'uri'
            docsite = URI.parse(project_module::DOCSITE)

            # provide uploading capability to websites hosted on RubyForge
            if docsite.host.include? '.rubyforge.org'
              target = "#{pub_rubyforge.userconfig['username']}@rubyforge.org:#{              File.join '/var/www/gforge-projects', options[:rubyforge_project], docsite.path}"
            end
          end

          if target
            cmd = ['rsync', '-auvz', 'doc/', "#{target}/"]
            cmd.push '--delete' if options[:upload_delete]
            cmd.concat options[:upload_options]

            sh(*cmd)
          end
        end

      # announcement
        desc 'Publish all release announcements.'
        task 'pub:ann' => %w[ pub:ann:forge pub:ann:raa ]

        desc 'Announce to RubyForge news.'
        task 'pub:ann:forge' => [:pub_rubyforge, :ann_text] do
          # TODO: post only if news item is not already there
          pub_rubyforge.post_news options[:rubyforge_project], ann_subject, ann_text
        end

        desc 'Announce to RAA (Ruby Application Archive).'
        task 'pub:ann:raa' => :ann_nfo_text do
          show_page_error = lambda do |page, message|
            raise "#{message}: #{(page/'h2').text} -- #{(page/'p').first.text.strip}"
          end

          resource = "#{options[:raa_project].inspect} project entry on RAA"

          require 'mechanize'
          agent = WWW::Mechanize.new
          page = agent.get "http://raa.ruby-lang.org/update.rhtml?name=#{options[:raa_project]}"

          if form = page.forms[1]
            resource << " (owned by #{form.owner.inspect})"

            form.description_style = 'Pre-formatted'
            form.description       = ann_nfo_text
            form.short_description = project_module::TAGLINE
            form.version           = project_module::VERSION
            form.url               = project_module::WEBSITE

            form.pass = options[:raa_password] or begin
              # ask for password
              require 'highline/import'
              ask("Password for #{resource}: ") {|q| q.echo = '' }
            end

            page = agent.submit form

            if page.title =~ /error/i
              show_page_error[page, "Could not update #{resource}"]
            end
          else
            show_page_error[page, "Could not access #{resource}"]
          end
        end

      # release packages
        desc 'Publish release packages to RubyForge.'
        task 'pub:pak' => [:pak, :pub_rubyforge] do
          uploader = lambda do |command, *files|
            pub_rubyforge.__send__ command, options[:rubyforge_project], options[:rubyforge_section], project_module::VERSION, *files
          end

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
          end
        end
  end

  ##
  # Provides a common configuration for the project's user manual:
  #
  # * Assigns the title, subtitle, date, and authors for the document.
  #
  #   You may override these assignments by reassigning these
  #   document parameters AFTER this method is invoked.
  #
  #   Refer to the "document parameters" for the XHTML
  #   format in the "erbook" user manual for details.
  #
  # * Provides the project's configuration as global variables in the document.
  #
  #   For example, <%= $version %> is the same as
  #   <%= project_module::VERSION %> in the document.
  #
  # * Defines a "project_summary" node for use in the document.  The body
  #   of this node should contain a brief introduction to the project.
  #
  # * Defines a "project_history" node for use in the document.  The body
  #   of this node should contain other nodes, each of which represent a
  #   single set of release notes for one of the project's releases.
  #
  # It is assumed that this method is called
  # from within the Inochi.rake() environment.
  #
  # @param [Symbol] project_symbol
  #   Name of the Ruby constant which serves
  #   as a namespace for the entire project.
  #
  # @param [ERBook::Document::Template] book_template
  #   The eRuby template which serves as the documentation for the project.
  #
  def book project_symbol, book_template
    project_module = fetch_project_module(project_symbol)

    # provide project constants as global variables to the user manual
    project_module::INOCHI.each_pair do |param, value|
      eval "$#{param} = value", binding
    end

    # set document parameters for the user manual
    $title    = project_module::DISPLAY
    $subtitle = project_module::TAGLINE
    $feeds    = { File.join(project_module::DOCSITE, 'ann.xml') => :rss }
    $authors  = Hash[
      *project_module::AUTHORS.map do |name, addr|
        # convert raw e-mail addresses into URLs for the erbook XHTML format
        addr = "mailto:#{addr}" unless addr =~ /^\w+:/

        [name, addr]
      end.flatten
    ]

    class << book_template
      def project_summary
        raise ArgumentError, 'block must be given' unless block_given?
        node do
          $project_summary_node = @nodes.last
          yield
        end
      end

      def project_history
        raise ArgumentError, 'block must be given' unless block_given?
        node do
          $project_history_node = @nodes.last
          yield
        end
      end
    end
  end

  ##
  # Returns the name of the main program executable, which
  # is the same as the project name fully in lowercase.
  #
  def calc_program_name project_symbol
    camel_to_snake_case(project_symbol).downcase
  end

  ##
  # Calculates the name of the project module from the given project name.
  #
  def calc_project_symbol project_name
    name = project_name.to_s.gsub(/\W+/, '_').squeeze('_').gsub(/^_|_$/, '')
    (name[0,1].upcase + name[1..-1]).to_sym
  end

  ##
  # Transforms the given input from CamelCase to snake_case.
  #
  def camel_to_snake_case input
    input = input.to_s.dup

    # handle camel case like FooBar => Foo_Bar
    while input.gsub!(/([a-z]+)([A-Z])(\w+)/) { $1 + '_' + $2 + $3 }
    end

    # handle abbreviations like XMLParser => XML_Parser
    while input.gsub!(/([A-Z]+)([A-Z])([a-z]+)/) { $1 + '_' + $2 + $3 }
    end

    input
  end

  private

  ##
  # Returns the path of the file in which this method was called.  Calls
  # to this method from within *THIS* file are excluded from the search.
  #
  def first_caller_file
    caller.each {|s| !s.include? __FILE__ and s =~ /^(.*?):\d+/ and break $1 }
  end

  ##
  # Returns the project module corresponding to the given symbol.
  # A new module is created if none already exists.
  #
  def fetch_project_module project_symbol
    if Object.const_defined? project_symbol
      project_module = Object.const_get(project_symbol)
    else
      project_module = Module.new
      Object.const_set project_symbol, project_module
    end

    project_module
  end
end
end

##
# utility methods
#

unless File.respond_to? :write
  ##
  # Writes the given content to the given file.
  #
  # @return number of bytes written
  #
  def File.write path, content
    File.open(path, 'wb') {|f| f.write content.to_s }
  end
end
