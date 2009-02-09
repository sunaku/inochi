class << Inochi
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

  INOCHI_LIBRARY_PATH = File.dirname(__FILE__)

  ##
  # Returns the path of the first file outside
  # Inochi's core from which this method was called.
  #
  def first_caller_file
    caller.each do |step|
      if file = step[/^.+(?=:\d+$)/]
        file = File.expand_path(file)
        base = File.dirname(file)

        break file unless base.index(INOCHI_LIBRARY_PATH) == 0
      end
    end
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

unless File.respond_to? :write
  ##
  # Writes the given content to the given file.
  #
  def File.write path, content
    open(path, 'wb') {|f| f.write content }
  end
end
