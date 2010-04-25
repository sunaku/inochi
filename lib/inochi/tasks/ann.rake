desc 'Build all release announcements.'
task :ann => %w[ ann:html ann:text ann:feed ]

# it has long been a tradition to use an "[ANN]" prefix
# when announcing things on the ruby-talk mailing list
@ann_subject_prefix = '[ANN] '

task :@ann_subject do
  unless @ann_subject
    Rake::Task[:@project].invoke
    @ann_subject = @ann_subject_prefix +
      @project_module::PROJECT + ' ' + @project_module::VERSION
  end
end

# fetch project description from manual
task :@ann_nfo_html_nodes do
  unless @ann_nfo_html_nodes
    begin
      head, body = fetch_nodes_between('h2#ABOUT', 'h1,h2,h3,h4,h5,h6')
    rescue => error
      error.message.insert 0,
        "The manual lacks a <H2> ABOUT heading.\n"
      raise error
    end

    @ann_nfo_html_nodes = body
  end
end

task :@ann_nfo_text do
  unless @ann_nfo_text
    Rake::Task[:@ann_nfo_html_nodes].invoke
    @ann_nfo_text = nodes_inner_text(@ann_nfo_html_nodes)
  end
end

# fetch release notes from manual
task :@ann_rel_html_body_nodes do
  unless @ann_rel_html_body_nodes
    begin
      head, body = fetch_nodes_between('h2#VERSIONS ~ h3', 'h1,h2,h3')
    rescue => error
      error.message.insert 0,
        "The manual lacks a <H3> heading under a <H2> VERSIONS heading.\n"
      raise error
    end

    @ann_rel_html_title_node = head
    @ann_rel_html_body_nodes = body
  end
end

# fetch authors list from manual
task :@project_authors_html_nodes do
  unless @project_authors_html_nodes
    begin
      head, body = fetch_nodes_between('h2#AUTHORS,h2#CREDITS',
                                       'h1,h2,h3,h4,h5,h6')
    rescue => error
      error.message.insert 0,
        "The manual lacks content under a <H2> AUTHORS or CREDITS heading.\n"
      raise error
    end

    @project_authors_html_nodes = body
  end
end

task :@project_authors_text do
  unless @project_authors_text
    Rake::Task[:@project_authors_html_nodes].invoke
    @project_authors_text = nodes_inner_text(@project_authors_html_nodes)
  end
end

# build release announcement
task :@ann_html do
  unless @ann_html
    Rake::Task[:@ann_nfo_html_nodes].invoke
    Rake::Task[:@ann_rel_html_body_nodes].invoke

    @ann_html = %{
      <center>
        <h1>#{@project_module::PROJECT}</h1>
        <h2>#{@project_module::TAGLINE}</h2>
        <p>#{@project_module::WEBSITE}</p>
      </center>
      #{@ann_nfo_html_nodes.join}
      #{@ann_rel_html_title_node}
      #{@ann_rel_html_body_nodes.join}
    }.strip

    @ann_html = resolve_html_links(@ann_html)
  end
end

task :@ann_text do
  unless @ann_text
    Rake::Task[:@ann_html].invoke
    @ann_text = convert_html_to_text(@ann_html)
  end
end

#-----------------------------------------------------------------------------
# HTML
#-----------------------------------------------------------------------------

@ann_html_dst = 'ann.html'

desc 'Build HTML announcement.'
task 'ann:html' => @ann_html_dst

file @ann_html_dst => @man_src do
  Rake::Task[:@ann_html].invoke
  File.write @ann_html_dst, @ann_html
end

CLOBBER.include @ann_html_dst

#-----------------------------------------------------------------------------
# plain text
#-----------------------------------------------------------------------------

@ann_text_dst = 'ann.txt'

desc 'Build plain text announcement.'
task 'ann:text' => @ann_text_dst

file @ann_text_dst => @man_src do
  Rake::Task[:@ann_text].invoke
  File.write @ann_text_dst, @ann_text
end

CLOBBER.include @ann_text_dst

#-----------------------------------------------------------------------------
# RSS feed
#-----------------------------------------------------------------------------

@ann_feed_dst = 'ann.xml'

desc 'Build RSS feed announcement.'
task 'ann:feed' => @ann_feed_dst

file @ann_feed_dst => @man_src do
  Rake::Task[:@project].invoke
  Rake::Task[:@ann_nfo_html_nodes].invoke
  Rake::Task[:@ann_rel_html_body_nodes].invoke

  require 'rss/maker'
  rss = RSS::Maker.make('2.0') do |feed|
    feed.channel.title = @ann_subject_prefix + @project_module::PROJECT
    feed.channel.link = @project_module::WEBSITE
    feed.channel.description = @ann_nfo_html_nodes.join

    item = feed.items.new_item
    item.link = @project_module::WEBSITE
    require 'time'
    item.date = Time.parse(@project_module::RELDATE)
    item.title = @ann_rel_html_title_node.inner_text
    item.description = @ann_rel_html_body_nodes.join
  end

  File.write @ann_feed_dst, rss
end

CLOBBER.include @ann_feed_dst

#-----------------------------------------------------------------------------
# helper logic
#-----------------------------------------------------------------------------

def nodes_inner_text nodes
  nodes.map {|n| n.inner_text }.join(' ').gsub(/\n/, ' ').squeeze(' ').strip
end

##
# Fetches all nodes between those matching the given head and tail selectors.
#
def fetch_nodes_between head_selector, tail_selector
  Rake::Task[:@man_html_dom].invoke

  head = @man_html_dom.at(head_selector)
  body = []

  tail = head
  while tail = tail.next_sibling and not tail.matches? tail_selector
    body << tail
  end

  [head, body, tail]
end

##
# Converts the given HTML into plain text.  we do this using
# lynx because (1) it outputs a list of all hyperlinks used
# in the HTML document and (2) it runs on all major platforms
#
def convert_html_to_text html
  # lynx's -dump option requires a .html file
  require 'tempfile'
  tmp_file = Tempfile.new($$).path + '.html'

  begin
    File.write tmp_file, html

    `lynx -dump #{tmp_file} -width 70`.
    #
    # improve readability of list items
    # by adding a blank line between them
    #
    gsub(/(\r?\n)( +\* \S)/, '\1\1\2')
  ensure
    File.delete tmp_file
  end
end

##
# Converts relative URLs in the given HTML into
# absolute URLs bound to the given base URL.
#
# http://en.wikipedia.org/wiki/URI_scheme#Generic_syntax
#
def resolve_html_links html, base_url = nil
  Rake::Task[:@project].invoke
  base_url ||= @project_module::WEBSITE

  require 'cgi'
  "<base href='#{CGI.escapeHTML base_url}'/> #{html}"
end
