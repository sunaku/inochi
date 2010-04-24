desc 'Instill Inochi into current directory.'
task :init do

  unless project_name = ENV[:project]
    raise ArgumentError, 'project name not specified'
  end

  library_name = Engine.calc_library_name(project_name)
  package_name = ENV[:package] || Engine.calc_package_name(library_name)

  project_version = '0.0.0'
  project_release = Time.now.strftime('%F')

  command_file = "bin/#{package_name}"
  create_from_rbs binding, command_file, 'command'
  chmod 0755, command_file

  create_from_rbs binding, 'inochi.opts'

  create_from_rbs binding, "lib/#{package_name}.rb", 'library'
  create_from_rbs binding, "lib/#{package_name}/inochi.rb"

  create_from_rbs binding, 'test/runner', 'test_runner'
  chmod 0755, 'test/runner'
  create_from_rbs binding, 'test/test_helper.rb', 'test_helper.rb'
  create_from_rbs binding, "test/#{package_name}_test.rb", 'library_test.rb'

  create_from_rbs binding, 'LICENSE'
  create_from_rbs binding, 'README'
  create_from_rbs binding, 'MANUAL'
  create_from_rbs binding, 'USAGE'
  create_from_rbs binding, 'EXAMPLES'
  create_from_rbs binding, 'HACKING'
  create_from_rbs binding, 'HISTORY'
  create_from_rbs binding, 'CREDITS'
  create_from_rbs binding, 'FURTHER'

end
