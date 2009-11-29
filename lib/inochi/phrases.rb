module Inochi
  ##
  # Interface to translations of human text used in a project.
  #
  # Translation bundles are YAML files (which must have
  # a ".yaml" file extension) which represent a single
  # Hash which maps input phrases to translated output.
  #
  # Input phrases may contain special placeholders (see Kernel#sprintf) which
  # are later substituted for actual values by the caller of the #[] method.
  #
  # ==== Examples
  #
  # A translation bundle file would look like this:
  #
  #   # this is a comment, ignored by the YAML parser
  #   input: output
  #   "foo: bar": "moz: qux"
  #   hello %s: %s ni'hau
  #
  class Phrases
    ##
    # All input phrases that were attempted to be translated.
    #
    attr_reader :attempted

    ##
    # The locale into which the #[] method will translate.
    #
    # The value of this attribute will be +nil+ if no
    # translation bundle has been loaded successfully.
    #
    attr_reader :locale

    ##
    # The directory which contains translation bundles used by the #[] method to
    # translate input phrases into the target locale (see #locale and #locale=).
    #
    attr_accessor :locale_directory

    ##
    # Locales marked as being preferred by environment variables.
    #
    # See http://www.linux.com/archive/feature/53781 for details.
    #
    attr_reader :environment_preferred_locales

    ##
    # Locales marked as being preferred by the Operating System.
    #
    attr_reader :system_preferred_locales

    ##
    # Locales given to #locale= by the user of this class.
    #
    attr_reader :user_preferred_locales

    def initialize locale_directory
      self.locale_directory = locale_directory

      require 'set'
      @attempted = Set.new

      # load language translations dynamically
      @phrases_by_bundle = Hash.new do |cache, bundle|
        bundle_file = File.join(@locale_directory, "#{bundle}.yaml")
        if File.exist? bundle_file
          begin
            require 'yaml'
            phrases = YAML.load_file(bundle_file).to_hash
          rescue => error
            error.message.insert 0,
              "Could not load translation bundle #{bundle_file.inspect}\n"
            raise
          end

          cache[bundle] = phrases
        end
      end

      detect_preferred_locales
    end

    ##
    # Sets the target locale, into which the #[] method will translate phrases.
    #
    def locale= value_or_array
      locales = convert_into_locales(Array(value_or_array))
      @user_preferred_locales = (locales + @user_preferred_locales).uniq
      try_bind_bundle_and_locale locales
    end

    ##
    # Returns a unique list of all preferred locales ordered
    # by user, environment, and then system preference.
    #
    def preferred_locales
      (
        @user_preferred_locales +
        @environment_preferred_locales +
        @system_preferred_locales
      ).uniq
    end

    ##
    # Translates the given phrase into the target
    # locale (see #locale and #locale=) and then
    # substitutes the given placeholder arguments
    # into the translation (see Kernel#sprintf).
    #
    # If a translation is not available for the
    # given phrase, then the given phrase will be
    # used in place of the actual translation.
    #
    def [] phrase, *words
      translate @bundle, phrase, *words
    end

    ##
    # Provides access to translations in any
    # language, regardless of the target
    # locale (see #locale and #locale=).
    #
    # For example, this method lets you access
    # Japanese translations via the #jp method
    # even if the target locale is French.
    #
    def method_missing meth, *args
      # ISO 639 language codes come in alpha-2 and alpha-3 forms
      # also allow an optional territory to be specified
      if meth.to_s =~ /^[a-z]{2,3}(_[A-Z]+)?$/
        translate meth, *args
      else
        super
      end
    end

    private

    def translate bundle, phrase, *words
      @attempted << phrase

      if phrases = @phrases_by_bundle[bundle]
        translation = phrases[phrase.to_s]
      end

      (translation || phrase).to_s % words
    end

    def detect_preferred_locales
      require 'locale'

      @environment_preferred_locales = convert_into_locales(
        # http://www.linux.com/archive/feature/53781
        %w[LC_ALL LC_MESSAGES LANG LANGUAGE].map do |var|
          ENV[var].to_s.split(/\s*:\s*/).reject {|s| s.empty? }
        end.flatten
      ).freeze

      @system_preferred_locales = Locale.candidates.freeze

      @user_preferred_locales = []

      try_bind_bundle_and_locale self.preferred_locales
    end

    def try_bind_bundle_and_locale locales
      locales.each do |locale|
        [
          locale.to_s,
          locale.to_simple.to_s,
          locale.language
        ].
        uniq.each do |bundle|
          if @phrases_by_bundle[bundle]
            @bundle = bundle
            @locale = locale
            return
          end
        end
      end
    end

    def convert_into_locales array
      begin
        Locale.set_current(*array)
        return Locale.current.uniq
      ensure
        # clear the locale cache so that the
        # next time Locale.current is called,
        # it redetects the original values
        Locale.clear
      end
    end
  end
end
