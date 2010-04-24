task :@project do
  begin
    @project_options_file = 'inochi.opts'
    @project_options = YAML.load_file(@project_options_file).to_hash

    # load the project module
    library_file = Dir['lib/*/inochi.rb'].first
    package_name = File.basename(File.dirname(library_file))
    library_name = File.read(library_file)[/\b(module|class)\b\s+(\w+)/, 2]

    $LOAD_PATH.unshift 'lib'
    require "#{package_name}/inochi"

    @project_module = Object.const_get(library_name)
    @project_package_name = package_name
    @project_library_name = library_name
    @project_gem_file = "#{@project_package_name}-#{@project_module::VERSION}.gem"
  rescue
    puts
    puts 'The current directory is not an Inochi project.'
    puts 'Run the `inochi init` command to make it one.'
    puts
    raise
  end
end
