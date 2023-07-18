#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'erb'
require 'fileutils'
require 'ostruct'

require 'words_counted'

ERB_FILES = %w[index.html.erb statistics.html.erb].freeze
TOKEN_REGEXP = /[\p{Alpha}\-'’]+/.freeze

def generate_chapter_link(row)
  %(<a href="#{row[:url]}">#{row[:title]}</a>)
end

def diffstat(file, max_value: 100)
  contents = File.read(file)
  total = contents.gsub('<ins>').count + contents.gsub('<del>').count
  display_width = [([max_value, total].min.to_f / max_value * 100).floor, 1].max

  <<~EOSVG
    <svg width="#{display_width + 35}" height="18" role="img"><g>
      <rect width="#{display_width}" height="18"></rect>
      <text x="#{display_width + 4}" y="15">#{total}</text>
    </g></svg>
  EOSVG
end

def generate_diff_link(row)
  pn_web = "diffs/#{row[:slug]}.html"
  pn = Pathname.new "_site/#{pn_web}"
  if pn.exist?
    %(<a href="#{pn_web}">#{diffstat(pn)}</a>)
  else
    '0'
  end
end

def generate_html_table(data)
  data.map do |row|
    <<~EOHTML
      <tr id="chapter-#{row[:slug]}">
      <td>#{generate_chapter_link row}</td>
      <td>#{generate_diff_link row}</td>
      </tr>
    EOHTML
  end.join
end

def count_words(slug)
  file = "_site/texts/#{slug}.txt"
  return unless File.exist? file

  tokens = File.open(file) do |f|
    WordsCounted::Tokeniser.new(f.read).tokenise(pattern: TOKEN_REGEXP)
  end
  WordsCounted::Counter.new(tokens).token_count
end

def generate_statistics_table(data)
  total = 0
  res = data.map do |row|
    wc = count_words(row[:slug])
    total += wc || 0
    <<~EOHTML
      <tr id="chapter-#{row[:slug]}"><td>#{generate_chapter_link row}</td><td>#{wc}</td></tr>
    EOHTML
  end
  res << "<tr><td>Total</td><td>#{total}</td></tr>"
  res.join
end

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
def generate_statistics_summary_table(data)
  total_map = Hash.new { |h, k| h[k] = 0 }
  volume_slug = {}
  data.each do |row|
    total_map[row[:volume]] += count_words(row[:slug]) || 0
    volume_slug[row[:volume]] = row[:slug] unless volume_slug.include? row[:volume]
  end

  res = total_map.keys.map do |key|
    "<tr><td><a href=\"\#chapter-#{volume_slug[key]}\">#{key}</a></td><td>#{total_map[key]}</td></tr>"
  end.join

  <<~EOHTML
    <table id="statistics-summary" style="width: unset; margin-left: unset">
      <tr><th>Volume</th><th>Word Count</th>
      #{res}
      <tr><td>Total</td><td>#{total_map.values.sum}</td></tr>
    </table>
  EOHTML
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize

def table_of_contents
  <<~EOHTML
    <p>
    <ul>
      <li><a href="#chapter-1-00">Volume 1</a></li>
      <li><a href="#chapter-rw1-00">Volume 1 (rewrite)</a></li>
      <li><a href="#chapter-interlude-2">Volume 2</a></li>
      <li><a href="#chapter-3-00-e">Volume 3</a></li>
      <li><a href="#chapter-4-00-k">Volume 4</a></li>
      <li><a href="#chapter-5-00">Volume 5</a></li>
      <li><a href="#chapter-6-00">Volume 6</a></li>
      <li><a href="#chapter-7-00">Volume 7</a></li>
      <li><a href="#chapter-8-00">Volume 8</a></li>
      <li><a href="#chapter-9-00">Volume 9</a></li>
    </ul>
    </p>
  EOHTML
end

def supporter_info
  <<~EOHTML
    <p>
      The code that generates this site is <a href="https://github.com/jonchang/wanderinginn.neocities.org">available on GitHub</a>. This site is made possible by the free labor and services provided by a bunch of people. Please consider supporting <a href="https://neocities.org/donate">Neocities</a>, the <a href="https://archive.org/donate/">Internet Archive</a>, or <a href="https://github.com/sponsors/jonchang">me with a donation</a>.
    </p>
  EOHTML
end

def frequently_asked_questions
  <<~EOHTML
    <h2>FAQ</h2>
    <dl>
      <dt>Where are the data for (chapter title)?</dt>
      <dd>Certain chapters aren't tracked. The most obvious ones are chapters that are still behind a Patreon password. Other chapters were written as Wordpress "pages" and thus aren't automatically tracked, such as the real April Fool's chapter, or the hidden rat interludes. These could be tracked, but I haven't gotten around to it yet.</dd>

      <dt>Why don't you exclude the author's notes and fanart galleries from your chapter text?</dt>
      <dd>I don't trust in my ability to instruct the computer to detect and remove these, and I'm not going to do it by hand, so this is the best compromise.</dd>

      <dt>Why do your word counts differ from (other word count tracking site)?</dt>
      <dd>See the answer to the previous question. Also, <a href="https://en.wikipedia.org/wiki/Word_count">there is no consistent definition of word count</a>, so pick whichever source satisfies your desire for numbers-go-up, and/or stop assuming that there is such a thing as an authoritative count.</dd>
    </dl>
  EOHTML
end

data = CSV.read('data.csv', headers: true, header_converters: :symbol)
data = data.sort { |a, b| a[0] <=> b[0] }

variables = OpenStruct.new
variables[:lastmod] = DateTime.now.strftime('%B %-d, %Y')
variables[:html_table] = generate_html_table(data)
variables[:statistics_table] = generate_statistics_table(data)
variables[:statistics_summary_table] = generate_statistics_summary_table(data)

ERB_FILES.each do |erb|
  basename = File.basename(erb, '.erb')
  html_file = "_site/#{basename}"  #=>"index.html"
  erb_str = File.read(erb)
  res = ERB.new(erb_str, trim_mode: '>').result(variables.instance_eval { binding })
  File.open(html_file, 'w') { |f| f.write(res) }
end

FileUtils.cp 'header-light.png', '_site/wise_papa_sloth_corrupted_by_his_own_power_can_no_leader_go_untainted.png'
FileUtils.cp 'header-dark.png', '_site/wise_papa_sloth_corrupted_by_his_own_power_can_no_leader_go_untainted_dark.png'
FileUtils.cp 'base.css', '_site/base.css'
FileUtils.cp 'homebrew.html', '_site/homebrew.html'
