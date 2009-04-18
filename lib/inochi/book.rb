#--
# Copyright 2008 Suraj N. Kurapati
# See the LICENSE file for details.
#++

class << Inochi
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
  # ==== Parameters
  #
  # [project_symbol]
  #   Name of the Ruby constant which serves
  #   as a namespace for the entire project.
  #
  # [book_template]
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

    book_template.extend Manual
  end

  module Manual
    ##
    # Defines a brief summary of this project.
    #
    def project_summary
      raise ArgumentError, 'block must be given' unless block_given?

      node do
        $project_summary_node = @nodes.last
        yield
      end
    end

    ##
    # Contains release notes for all project releases.
    #
    def project_history
      raise ArgumentError, 'block must be given' unless block_given?

      node do
        $project_history_node = @nodes.last
        yield
      end
    end
  end
end
