@man_asciidoc_src = FileList['MANUAL', '[A-Z]*[A-Z]']
@man_asciidoc_dst = 'man.txt'

@man_html_dst = 'man.html'
@man_roff_dst = "man/man1/#{@project_package_name}.1"

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

build_asciidoc_args = lambda do
  [('-v' if Rake.application.options.trace), @man_asciidoc_dst].compact
end

file @man_html_dst => @man_asciidoc_dst do
  atts = %W[data-uri toc stylesheet=#{__FILE__.ext 'css'}] +
    Array(@project_config[:man_asciidoc_attributes])

  opts = atts.map {|a| ['-a', a] }.flatten
  args = opts + build_asciidoc_args.call

  sh 'asciidoc', '-o', @man_html_dst, *args
end

CLOBBER.include @man_html_dst

file @man_roff_dst => @man_asciidoc_dst do
  args = build_asciidoc_args.call
  mkdir_p dir = File.dirname(@man_roff_dst)
  sh 'a2x', '-f', 'manpage', '-D', dir, *args
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
