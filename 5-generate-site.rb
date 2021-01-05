#!/usr/bin/env ruby

require 'csv'
require 'erb'
require 'fileutils'
require 'ostruct'

ERB_FILES = %w[index.html.erb]

def generate_chapter_link(row)
    %Q|<a name="chapter-#{row[:slug]}" href="#{row[:url]}">#{row[:title]}</a>|
end

def diffstat(file, max_value: 100)
  contents = File.read(file)
  ins = '<ins>'
  del = '<del>'
  plus = contents.gsub(ins).count
  minus = contents.gsub(del).count
  total = plus + minus
  display_width = [(([max_value, total].min).to_f / max_value * 100).floor, 1].max

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
    %Q|<a href="#{pn_web.to_s}">#{diffstat(pn)}</a>|
  else
    "0"
  end
end

def generate_html_table(dd)
  dd.map do |row|
    <<~EOHTML
    <tr>
    <td>#{generate_chapter_link row}</td>
    <td>#{generate_diff_link row}</td>
    </tr>
    EOHTML
  end.join
end

data = CSV.read("data.csv", headers: true, header_converters: :symbol)
data = data.sort { |a, b| a[0] <=> b[0] }

variables = OpenStruct.new
variables[:lastmod] = DateTime.now.strftime("%B %-d, %Y")
variables[:html_table] = generate_html_table(data)

ERB_FILES.each do |erb|
  html_file = "_site/" + File.basename(erb, ".erb") #=>"index.html"
  erb_str = File.read(erb)
  res = ERB.new(erb_str, trim_mode: ">").result(variables.instance_eval { binding })
  File.open(html_file, 'w') { |f| f.write(res) }
end

FileUtils.cp "header.png", "_site/wise_papa_sloth_corrupted_by_his_own_power_can_no_leader_go_untainted.png"
FileUtils.cp "homebrew.html", "_site/homebrew.html"
