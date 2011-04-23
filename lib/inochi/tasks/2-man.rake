@man_asciidoc_src = FileList['MANUAL', '[A-Z]*[A-Z]']
@man_asciidoc_dst = 'man.txt'

@man_html_dst = 'man.html'
@man_roff_dst = "man/man1/#{@project_package_name}.1"
@man_docbook_dst = @man_roff_dst + '.xml'

desc 'Build the help manual.'
task :man => [@man_html_dst, @man_roff_dst]

#-----------------------------------------------------------------------------

# Run manual through Ember to produce a single input file for AsciiDoc.
file @man_asciidoc_dst => @man_asciidoc_src do

  input = [
    ":revdate: #{@project_module::RELDATE}",
    ":revnumber: #{@project_module::VERSION}",

    "= #{@project_package_name}(1)",

    '== NAME',
    "#{@project_package_name} - #{@project_module::TAGLINE}",

    "%+ #{@man_asciidoc_src.first.inspect}",
  ].join("\n\n")

  options = {
    :shorthand => true,
    :unindent => true,
    :infer_end => true
  }

  require 'ember'
  output = Ember::Template.new(input, options).render

  File.write @man_asciidoc_dst, output
end

CLEAN.include @man_asciidoc_dst

#-----------------------------------------------------------------------------

build_asciidoc_args = proc do |*atts|
  atts.concat Array(@project_config[:man_asciidoc_attributes])
  args = atts.map {|a| ['-a', a] }.flatten

  args.push '-v' if Rake.application.options.trace
  args.push @man_asciidoc_dst

  args
end

file @man_html_dst => @man_asciidoc_dst do
  args = build_asciidoc_args.call(
    'pygments', # for better syntax coloring than GNU Source Highlight
    'data-uri', # to ensure the output is a monolithic HTML document
    'toc', 'stylesheet=' + __FILE__.ext('css')
  )
  sh 'asciidoc', '-o', @man_html_dst, *args
end

CLOBBER.include @man_html_dst

file @man_docbook_dst => @man_asciidoc_dst do
  args = build_asciidoc_args.call
  mkdir_p File.dirname(@man_docbook_dst)
  sh 'asciidoc', '-o', @man_docbook_dst, '-d', 'manpage', '-b', 'docbook', *args
end

CLOBBER.include @man_docbook_dst

file @man_roff_dst => @man_docbook_dst do
  sh 'xsltproc', '-o', @man_roff_dst, '--nonet',
    'http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl',
    @man_docbook_dst
end

CLOBBER.include @man_roff_dst

#-----------------------------------------------------------------------------

task :@man_html do
  unless @man_html
    Rake::Task[@man_html_dst].invoke
    @man_html = File.read(@man_html_dst)
  end
end

task :@man_html_dom do
  unless @man_html_dom
    Rake::Task[:@man_html].invoke

    require 'nokogiri'
    @man_html_dom = Nokogiri::HTML(@man_html)
  end
end
