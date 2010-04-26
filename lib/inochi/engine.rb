require 'yaml'
require 'time'
require 'rake'
require 'rake/clean'
require 'shellwords'

module Inochi
  class Engine

    require 'inochi/generate'
    include Inochi::Generate

    def run
      register_rake_tasks
      run_rake_tasks
    end

    ##
    # Renders the given RBS (ruby string) file
    # and/or template inside the given binding.
    #
    def self.render_rbs binding, filename, template = File.read(filename)
      here = "TEMPORARY_HERE_DOC#{object_id}TEMPORARY_HERE_DOC"
      eval("<<#{here}\n#{template}\n#{here}", binding, filename).chomp
    end

    private

    def run_rake_tasks
      task :default do
        Rake.application.options.show_task_pattern = //
        Rake.application.display_tasks_and_comments
      end

      Rake.application.init 'inochi'
      Rake.application.top_level
    end

    def register_rake_tasks
      Dir[File.dirname(__FILE__) + '/tasks/*.rake'].sort.each do |file|
        instance_eval File.read(file), file
      end
    end

    TEMPLATE_DIR = File.join(File.dirname(__FILE__), 'templates')

    ##
    # Renders the given RBS template file (found in the
    # TEMPLATE_DIR directory) to the given output file.
    #
    def create_from_rbs binding, output_file, template_file = File.basename(output_file)
      actual_template_file = "#{TEMPLATE_DIR}/#{template_file}.rbs"
      create output_file, self.class.render_rbs(binding, actual_template_file)
    end

    ##
    # Writes the given contents to the file at the given
    # path.  If the given path already exists, then a
    # backup is created before invoking the merging tool.
    #
    def create path, body, merger = ENV[:merger]
      generate path, body do |*files|
        system "#{merger} #{Shellwords.join files}" if merger
      end
    end

    ##
    # Returns the name of the main program executable, which
    # is the same as the project name fully in lowercase.
    #
    def self.calc_package_name library_name
      camel_to_snake_case(library_name).downcase
    end

    ##
    # Calculates the name of the project module from the given project name.
    #
    def self.calc_library_name project_name
      name = project_name.to_s.gsub(/\W+/, '_').squeeze('_').gsub(/^_|_$/, '')
      (name[0,1].upcase + name[1..-1]).to_sym
    end

    ##
    # Transforms the given input from CamelCase to snake_case.
    #
    def self.camel_to_snake_case input
      input = input.to_s.dup

      # handle camel case like FooBar => Foo_Bar
      while input.gsub!(/([a-z]+)([A-Z])(\w+)/) { $1 + '_' + $2 + $3 }
      end

      # handle abbreviations like XMLParser => XML_Parser
      while input.gsub!(/([A-Z]+)([A-Z])([a-z]+)/) { $1 + '_' + $2 + $3 }
      end

      input
    end

  end
end
