class << Inochi
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
  #     The default value is the value of the :project parameter
  #     in lowercase and CamelCase converted into snake_case.
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
      $LOAD_PATH << project_libs unless $LOAD_PATH.include? project_libs

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
      project_config[:version].extend Version

      project_config.each_pair do |param, value|
        project_module.const_set param.to_s.upcase, value
      end

    project_module
  end

  module Version
    # Returns the major number in this version.
    def major
      to_s[/^\d+/]
    end

    # Returns a string describing any version with the current major number.
    def series
      "#{major}.x.x"
    end

    # Returns a Gem::Requirement expression.
    def requirement
      "~> #{major}"
    end
  end
end
