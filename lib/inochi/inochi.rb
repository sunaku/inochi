require 'rubygems'

module Inochi
class << self
  ##
  # Provides a common configuration for the project module,
  # which serves as a namespace for the entier project.
  #
  # * The program description (the sequence of non-blank lines at the
  #   top of the file in which this method is invoked) is properly
  #   formatted and displayed in the help information of the program.
  #
  # * The program version information is fetched from the project module
  #   and formatted in YAML fashion for easy consumption by other tools.
  #
  # * The project lib/ directory is added to the Ruby load path.
  #
  # This method must be invoked from immediately within (that is, not from
  # within any of its descendant directories) the project lib/ directory.
  #
  # @param [Symbol] project_symbol
  #   Name of the Ruby constant which serves
  #   as a namespace for the entire project.
  #
  # @param [Hash] project_config
  #   Project configuration parameters:
  #
  #   * [String] :project
  #       Name of the project.
  #
  #   * [String] :version
  #       Version of the project.
  #
  #   * [String] :release
  #       Date when this version was released.
  #
  #   * [String] :website
  #       URL of the project website.
  #
  #   * [String] :display
  #       The project name and version together.
  #
  #   * [String] :program
  #       Name of the main project executable.
  #
  #   * [String] :install
  #       Path to the directory which contains the project.
  #
  #   * [Hash] :require
  #       The names and version constraints of ruby gems required by
  #       this project.  This information must be expressed as follows:
  #
  #       * Each hash key must be the name of a ruby gem.
  #
  #       * Each hash value must be either +nil+, or a
  #         single version number requirement string
  #         (see Gem::Requirement), or an array of
  #         version number requirement strings.
  #
  # @return [Module] The project module.
  #
  def init project_symbol, project_config = {}
    project_module = fetch_project_module(project_symbol)

    # this method is not re-entrant
      @already_seen ||= []
      return project_module if @already_seen.include? project_module
      @already_seen << project_module

    # put project on Ruby load path
      project_file = first_caller_file
      $LOAD_PATH.unshift File.dirname(project_file)

    # set configuration defaults
      project_config[:project] ||= project_symbol.to_s
      project_config[:version] ||= '0.0.0'
      project_config[:release] ||= Time.now.strftime('%F')
      project_config[:website] ||= ''
      project_config[:display] ||= "#{project_config[:project]} #{project_config[:version]}"
      project_config[:program] ||= calc_program_name(project_symbol)
      project_config[:install] ||= File.expand_path(File.join(File.dirname(project_file), '..'))
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
  #   formatted and displayed in the help information of the program.
  #
  # * The program version information is automatically
  #   fetched from the given project constant and formatted
  #   in YAML fashion for easy consumption by other tools.
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
        # show program description
        text File.read(program_file)[/\A.*?^$\n/m]. # grab the header
             gsub(/^# ?/, ''). # strip the comment markers
             sub(/\A!.*?\n/, '') # omit the shebang line
        text ''

        instance_eval(&trollop_config) if trollop_config

        # show version information
        version %w[PROJECT VERSION RELEASE WEBSITE INSTALL].map {|c|
          "#{c.downcase}: #{project_module.const_get c}"
        }.join("\n")
      end
  end

  ##
  # Provides a common configuration for the main project Rakefile:
  #
  # * The author name and email address is automatically extracted
  #   from the first Copyright notice in the project LICENSE file.
  #
  # * The README file is automatically generated
  #   from the Abstract section of the user manual.
  #
  # @param [Symbol] project_symbol
  #   Name of the Ruby constant which serves
  #   as a namespace for the entire project.
  #
  # @param [Hash] options
  #   Additional method parameters, which are all optional:
  #
  #   * [String] :rubyforge_project
  #       Name of the RubyForge project where
  #       release packages will be published.
  #
  #   * [String] :rubyforge_section
  #       Name of the RubyForge project's File Release System
  #       section where release packages will be published.
  #
  #   * [String] :history_node_id
  #       ID of the node in the user manual which
  #       contains the history of release notes.
  #
  # @param gem_config
  #   Block that is passed to Gem::specification.new()
  #   for additonal gem configuration.
  #
  def rake project_symbol, options = {}, &gem_config # :yields: gem_spec
    # load the project module
      program_name = calc_program_name(project_symbol)

      require File.join('lib', program_name)
      project_module = fetch_project_module(project_symbol)

    # set default options
      options[:rubyforge_project] ||= program_name
      options[:rubyforge_section] ||= program_name
      options[:history_node_id] ||= 'history'

    require 'rake/clean'

    # packaging
      desc 'Build release packages.'
      task :pak => [:clobber, :doc] do
        sh $0, 'package'
      end

      # ruby gem
        require 'rake/gempackagetask'

        gem = Gem::Specification.new do |gem|
          if author_info = fetch_copyright_holders.first
            gem.author, gem.email = author_info
          end

          gem.rubyforge_project = options[:rubyforge_project]

          # XXX: In theory, `gem.name` should be assigned to
          #      ::PROJECT instead of ::PROGRAM
          #
          #      In practice, ::PROJECT may contain non-word
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
          gem.summary     = project_module::SUMMARY
          gem.description = gem.summary
          gem.homepage    = project_module::WEBSITE
          gem.files       = FileList['**/*'].exclude('pkg', '_darcs')
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

    # documentation
      desc 'Build the documentation.'
      task :doc => %w[ doc:api doc:man doc:hey doc:ann ]

      # user manual
        doc_man_dep = FileList['doc/*.erb']
        doc_man_src = 'doc/index.erb'
        doc_man_dst = 'doc/index.xhtml'

        doc_man_doc = nil
        doc_man_doc_loader = lambda do
          unless doc_man_doc
            require 'erbook' unless defined? ERBook
            doc_man_txt = File.read(doc_man_src)
            doc_man_doc = ERBook::Document.new(:xhtml, doc_man_txt, doc_man_src, :unindent => true)
          end
        end

        desc 'Build the user manual.'
        task 'doc:man' => doc_man_dst

        # xhtml_to_text = lambda do |xhtml|
        #   IO.popen('w3m -T text/html -dump -cols 60', 'w+') do |io|
        #     io.write xhtml
        #     io.close_write
        #     io.read
        #   end
        # end

        file doc_man_dst => doc_man_dep do
          doc_man_doc_loader.call
          File.write doc_man_dst, doc_man_doc
        end

        CLOBBER.include doc_man_dst

      # readme file
        doc_hey_dst = 'README.html'

        desc 'Build the welcome guide.'
        task 'doc:hey' => doc_hey_dst

        file doc_hey_dst => doc_man_src do
          message = 'Please see %s in your web browser.'

          File.write doc_hey_dst, %{
            <!-- #{message % [doc_man_dst]} -->
            <html>
              <head>
                <meta http-equiv="refresh" content="0; url=#{doc_man_dst}"/>
              </head>
              <body>
                #{message % [%{<a href="#{doc_man_dst}">#{doc_man_dst}</a>}]}
              </body>
            </html>
          }.gsub(/^\s+/, '')
        end

        CLOBBER.include doc_hey_dst

      # API reference
        doc_api_dst = 'doc/api'

        desc 'Build API reference documentation.'
        task 'doc:api' => [doc_api_dst, doc_hey_dst]

        require 'yard'
        YARD::Rake::YardocTask.new doc_api_dst do |t|
          t.options.push '--protected', '-d', doc_api_dst, '-r', doc_hey_dst
        end

        CLOBBER.include doc_api_dst, '.yardoc'

        # require 'rake/rdoctask'
        # require 'darkfish-rdoc'

        # Rake::RDocTask.new 'doc:api' do |t|
        #   t.rdoc_dir = 'doc/api'
        #   t.rdoc_files.include('**/*.rb').exclude('pkg', '_darcs')
        #   t.options.concat %w[-f darkfish -SHN]
        # end

      # release announcement
        doc_ann_html_dst = 'ANN.html'
        doc_ann_feed_dst = 'doc/ann.xml'

        desc 'Generate release announcements.'
        task 'doc:ann' => [doc_ann_html_dst, doc_ann_feed_dst]

        # fetch release notes from user manual
        doc_ann_doc = nil
        doc_ann_doc_loader = lambda do
          unless doc_ann_doc
            doc_man_doc_loader.call

            history_id = options[:history_node_id]
            if history = doc_man_doc.nodes.find {|n| n.id == history_id }
              if release = history.children.first
                doc_ann_doc = release
              else
                raise "The #{history_id.inspect} node in the user manual is empty."
              end
            else
              raise "Could not find #{history_id.inspect} node in the user manual."
            end
          end
        end

        # build HTML for announcement
        file doc_ann_html_dst do
          doc_ann_doc_loader.call
          File.write doc_ann_html_dst, doc_ann_doc.output
        end

        CLOBBER.include doc_ann_html_dst

        # build RSS feed for announcement
        file doc_ann_feed_dst do
          doc_ann_doc_loader.call

          require 'time'
          require 'rss/maker'
          feed = RSS::Maker.make('2.0') do |feed|
            feed.channel.title       = "[ANN] #{project_module::PROJECT}"
            feed.channel.link        = project_module::WEBSITE
            feed.channel.description = project_module::SUMMARY

            item             = feed.items.new_item
            item.title       = doc_ann_doc.title
            item.link        = project_module::WEBSITE
            item.date        = Time.parse(item.title)
            item.description = doc_ann_doc.output
          end

          File.write doc_ann_feed_dst, feed
        end

        CLOBBER.include doc_ann_feed_dst

    # releasing
      desc 'Publish a new release.'
      task 'pub' => %w[ pub:pak pub:doc pub:ann ]

      # def already_published?
      #   sh 'rubyforge', 'login'
      # end

      # documentation
        desc 'Publish documentation to project website.'
        task 'pub:doc' => :doc

      # release announcement
        desc 'Publish release announcement to the world.'
        task 'pub:ann' => :ann do
          # TODO: send mail to ruby-talk
          # post news to RubyForge
        end

      # release packages
        desc 'Publish release packages to RubyForge.'
        task 'pub:pak' => :pak do
          # TODO: use RUbyforge gem's ruby interface rather than sh()
          sh 'rubyforge', 'login'

          pusher = lambda do |cmd, pkg|
            sh 'rubyforge', cmd, '--release_date', project_module::RELEASE,
               gem.rubyforge_project, options[:rubyforge_section], gem.version, pkg
          end

          # push ONLY the first package using 'add_release' because that command
          # creates a new sub-section on the RubyForge download page; we do not
          # want one package per sub-section on the RubyForge download page!
          first, *rest = Dir['pkg/*.[a-z]*']

          pusher['add_release', first]
          rest.each {|file| pusher['add_file', file] }
        end
  end

  ##
  # Provides a common configuration for the project's user manual:
  #
  def book project_symbol
    project_module = fetch_project_module(project_symbol)

    $title    = "#{project_module::DISPLAY} user manual"
    $subtitle = project_module::SUMMARY
    $authors  = Hash[*fetch_copyright_holders]
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
  # Returns the name of the main program executable, which
  # is the same as the project name fully in lowercase.
  #
  def calc_program_name project_symbol
    project_symbol.to_s.downcase
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

  ##
  # Returns an array of [holder_name, holder_email]
  # copyright information from the given license file.
  #
  def fetch_copyright_holders license_file = 'LICENSE'
    File.read(license_file).scan %r{Copyright.*\d+\s+(.*)(?:\s+<(.*?)>)}
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
