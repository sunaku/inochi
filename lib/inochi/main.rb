#--
# Copyright protects this work.
# See LICENSE file for details.
#++

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
# It is assumed that this method is invoked from only within
# the main project executable (in the project bin/ directory).
#
# ==== Parameters
#
# [project_symbol]
#   Name of the Ruby constant which serves
#   as a namespace for the entire project.
#
# [trollop_args]
#   Optional array of arguments for Trollop::options().
#
# [trollop_config]
#   Optional block parameter passed to Trollop::options().
#
# Returns the result of Trollop::options().
#
def Inochi.main project_symbol, *trollop_args, &trollop_config
  program_file = first_caller_file
  program_name = File.basename(program_file)
  program_home = File.dirname(File.dirname(program_file))

  # load the project module
    require File.join(program_home, 'lib', program_name)
    project_module = fetch_project_module(project_symbol)

  # parse command-line options
    require 'trollop'

    options = Trollop.options(*trollop_args) do

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

      opt :manual, 'Show the user manual'
      opt :locale, 'Set preferred language', :type => :string
    end

    if options[:manual]
      require 'launchy'

      manual = File.join(project_module::INSTALL, 'doc', 'index.html')
      Launchy::Browser.run manual

      exit
    end

    if locale = options[:locale]
      project_module::PHRASES.locale = locale
    end

    options
end
