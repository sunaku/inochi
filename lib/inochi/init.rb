#--
# Copyright protects this work.
# See LICENSE file for details.
#++

require 'yaml'

module Inochi
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
  # ==== Parameters
  #
  # [project_symbol]
  #   Name of the Ruby constant which serves
  #   as a namespace for the entire project.
  #
  # [project_config]
  #   Optional hash of project configuration parameters:
  #
  #   [:project]
  #     Name of the project.
  #
  #     The default value is the value of the project_symbol parameter.
  #
  #   [:tagline]
  #     An enticing, single line description of the project.
  #
  #     The default value is an empty string.
  #
  #   [:website]
  #     URL of the published project website.
  #
  #     The default value is an empty string.
  #
  #   [:docsite]
  #     URL of the published user manual.
  #
  #     The default value is the same value as the :website parameter.
  #
  #   [:program]
  #     Name of the main project executable.
  #
  #     The default value is the value of the :project parameter
  #     in lowercase and CamelCase converted into snake_case.
  #
  #   [:version]
  #     Version of the project.
  #
  #     The default value is "0.0.0".
  #
  #   [:release]
  #     Date when this version was released.
  #
  #     The default value is the current time.
  #
  #   [:display]
  #     How the project name should be displayed.
  #
  #     The default value is the project name and version together.
  #
  #   [:install]
  #     Path to the directory which contains the project.
  #
  #     The default value is one directory above the parent
  #     directory of the file from which this method was called.
  #
  #   [:require]
  #     Hash containing the names and version constraints of RubyGems required
  #     to run this project.  This information must be expressed as follows:
  #
  #     * Each hash key must be the name of a ruby gem.
  #
  #     * Each hash value must be either +nil+, a single version number
  #       requirement string (see Gem::Requirement) or an Array thereof.
  #
  #     The default value is an empty Hash.
  #
  #   [:develop]
  #     Hash containing the names and version constraints of RubyGems required
  #     to build this project.  This information must be expressed as follows:
  #
  #     * Each hash key must be the name of a ruby gem.
  #
  #     * Each hash value must be either +nil+, a single version number
  #       requirement string (see Gem::Requirement) or an Array thereof.
  #
  #     The default value is an empty Hash.
  #
  # ==== Returns
  #
  # The newly configured project module.
  #
  def Inochi.init project_symbol, project_config = {}
    project_module = fetch_project_module(project_symbol)

    # this method is not re-entrant
      @already_seen ||= []
      return project_module if @already_seen.include? project_module
      @already_seen << project_module

    # put project on Ruby load path
      project_file = first_caller_file
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
      project_config[:develop] ||= {}

    # establish gem version dependencies and
    # sanitize the values while we're at it
      src = project_config[:require].dup
      dst = project_config[:require].clear

      src.each_pair do |gem_name, version_reqs|
        dst[gem_name] = require_gem_version(gem_name, version_reqs)
      end

    # make configuration parameters available as constants
      project_config[:inochi]  = project_config
      project_config[:phrases] = Phrases.new project_config[:install]
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

  ##
  # Interface to translations of human text used in a project.
  #
  class Phrases
    def initialize project_install_dir
      # load language translations dynamically
        lang_dir = File.join(project_install_dir, 'lang')

        @phrases_by_language = Hash.new do |cache, language|
          # store the phrase upon failure so that
          # the phrases() method will know about it
          phrases = Hash.new {|h,k| h[k] = nil }

          lang_file = File.join(lang_dir, "#{language}.yaml")
          lang_data = YAML.load_file(lang_file) rescue nil
          phrases.merge! lang_data if lang_data

          cache[language] = phrases
        end

      # detect user's preferred locale
      self.locale = ENV['LC_ALL'] || ENV['LC_MESSAGES'] || ENV['LANG']
    end

    # The locale into which the #[] method will translate phrases.
    attr_reader :locale

    def locale= locale
      @locale = locale.to_s

      # extract the language portion of the locale
      language  = @locale[/^[[:alpha:]]+/].to_s
      @language = language =~ /^(C|POSIX)?$/i ? :en : language.downcase.to_sym
    end

    ##
    # Returns all phrases that underwent (or
    # attempted) translation via this object.
    #
    def phrases
      @phrases_by_language.values.map {|h| h.keys }.flatten.uniq.sort
    end

    ##
    # Translates the given phrase into the target
    # locale (see #locale and #locale=) and then
    # substitutes the given placeholder arguments
    # into the translation (see Kernel#sprintf).
    #
    # If a translation is not available for the given phrase,
    # then the given phrase will be used as-is, untranslated.
    #
    def [] phrase, *words
      translate @language, phrase, *words
    end

    ##
    # Provides access to translations in any language, regardless
    # of the target locale (see #locale and #locale=).
    #
    # For example, you can access Japanese translations via
    # the #jp method even if the target locale is French.
    #
    def method_missing meth, *args
      # ISO 639 language codes come in alpha-2 and alpha-3 forms
      if meth.to_s =~ /^[a-z]{2,3}$/
        translate meth, *args
      else
        super
      end
    end

    private

    ##
    # Translates the given phrase into the given language and then substitutes
    # the given placeholder arguments into the translation (see Kernel#sprintf).
    #
    # If the translation is not available, then
    # the given string will be used instead.
    #
    def translate language, phrase, *words
      (@phrases_by_language[language][phrase.to_s] || phrase).to_s % words
    end
  end
end
