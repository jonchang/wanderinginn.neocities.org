#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'erb'
require 'fileutils'
require 'ostruct'

require 'words_counted'

ERB_FILES = %w[index.html.erb statistics.html.erb].freeze

def generate_chapter_link(row)
  %(<a href="#{row[:url]}">#{row[:title]}</a>)
end

def diffstat(file, max_value: 100)
  contents = File.read(file)
  ins = '<ins>'
  del = '<del>'
  plus = contents.gsub(ins).count
  minus = contents.gsub(del).count
  total = plus + minus
  display_width = [([max_value, total].min.to_f / max_value * 100).floor, 1].max

  <<~EOSVG
    <svg width="#{display_width + 35}" height="18" role="img">
    <g><rect width="#{display_width}" height="18"></rect>
       <text x="#{display_width + 4}" y="15">#{total}</text>
    </g>
    </svg>
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
    WordsCounted::Tokeniser.new(f.read).tokenise
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

def table_of_contents
  <<~EOHTML
    <p>
    <ul>
      <li><a href="#chapter-1-00">Volume 1</a></li>
      <li><a href="#chapter-interlude-2">Volume 2</a></li>
      <li><a href="#chapter-3-00-e">Volume 3</a></li>
      <li><a href="#chapter-4-00-k">Volume 4</a></li>
      <li><a href="#chapter-5-00">Volume 5</a></li>
      <li><a href="#chapter-6-00">Volume 6</a></li>
      <li><a href="#chapter-7-00">Volume 7</a></li>
      <li><a href="#chapter-8-00">Volume 8</a></li>
    </ul>
    </p>
  EOHTML
end

data = CSV.read('data.csv', headers: true, header_converters: :symbol)
data = data.sort { |a, b| a[0] <=> b[0] }

variables = OpenStruct.new
variables[:lastmod] = DateTime.now.strftime('%B %-d, %Y')
variables[:html_table] = generate_html_table(data)
variables[:statistics_table] = generate_statistics_table(data)

ERB_FILES.each do |erb|
  basename = File.basename(erb, '.erb')
  html_file = "_site/#{basename}"  #=>"index.html"
  erb_str = File.read(erb)
  res = ERB.new(erb_str, trim_mode: '>').result(variables.instance_eval { binding })
  File.open(html_file, 'w') { |f| f.write(res) }
end

FileUtils.cp 'header.png', '_site/wise_papa_sloth_corrupted_by_his_own_power_can_no_leader_go_untainted.png'
FileUtils.cp 'homebrew.html', '_site/homebrew.html'
