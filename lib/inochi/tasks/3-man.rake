@man_src = FileList['MANUAL', '[A-Z]*[A-Z]']
@man_html_dst = 'man.html'
@man_ronn_dst = 'man.ronn'
@man_roff_dst_glob = 'man/man*/*.?{,.gz}'

desc 'Build the help manual.'
task :man => @man_html_dst

file @man_html_dst => @man_src do
  Rake::Task[:@man_doc].invoke

  # write ronn version

  # write roff version
  roff_file = "man/man#{@man_doc.section}/#{@man_doc.basename}"
  mkdir_p File.dirname(roff_file)

  require 'zlib'
  Zlib::GzipWriter.open(roff_file + '.gz') do |gz|
    gz.write @man_doc.to_roff
  end

  # write html version
  File.write @man_html_dst, @man_doc.to_html
end

CLOBBER.include @man_html_dst, @man_ronn_dst, @man_roff_dst_glob

# loads the manual as a Ronn document
task :@man_doc => @man_src do
  unless @man_doc
    Rake::Task[:@project].invoke

    # render eRuby template
    ember_input =
      "# #{@project_package_name}(1) - #{@project_module::TAGLINE}\n\n"\
      "%+ #{@man_src.first.inspect}"

    ember_opts = {
      :source_file => :@man_doc,
      :shorthand => true,
      :unindent => true,
      :infer_end => true,
    }

    require 'ember'
    ronn_input = Ember::Template.new(ember_input, ember_opts).render
    File.write @man_ronn_dst, ronn_input # for debugging / sanity check

    # build Ronn document
    require 'date'
    ronn_opts = {
      :date => Date.parse(@project_module::RELDATE),
      :manual => "Version #{@project_module::VERSION}",
      :styles => %w[ man toc 80c ]
    }
    ronn_file = "#{@project_package_name}.1.ronn"

    require 'ronn'
    @man_doc = Ronn::Document.new(ronn_file, ronn_opts) { ronn_input }
  end
end

task :@man_html do
  unless @man_html
    Rake::Task[:@man_doc].invoke
    @man_html = @man_doc.to_html
  end
end

task :@man_html_dom do
  unless @man_html_dom
    Rake::Task[:@man_html].invoke

    require 'nokogiri'
    @man_html_dom = Nokogiri::HTML(@man_html)
  end
end

