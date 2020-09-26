#!/usr/bin/env ruby

require "erb"
require "ostruct"
require 'csv'

data = CSV.read("data.csv", headers: true, header_converters: :symbol)

data = data.sort { |a, b| a[0] <=> b[0] }

erb_file = "index.html.erb"
html_file = "_site/" + File.basename(erb_file, ".erb") #=>"index.html"

erb_str = File.read(erb_file)

variables = OpenStruct.new

def generate_chapter_link(row)
    %Q|<a name="chapter-#{row[:slug]}" href="#{row[:url]}">#{row[:title]}</a>|
end

def diffstat(file, max_width: 10)
  contents = File.read(file)
  ins = '<ins>'
  del = '<del>'
  plus = contents.gsub(ins).count
  minus = contents.gsub(del).count
  total = plus + minus
  if total <= max_width
    "#{total.to_s.ljust(4)}#{"+" * plus}#{"-" * minus}"
  else
    diff = (plus.to_f / total * max_width).round
    "#{total.to_s.ljust(4)}#{"+" * diff}#{"-" * (max_width - diff)}"
  end
end

def generate_diff_link(row)
  pn_web = "diffs/#{row[:slug]}.html"
  pn = Pathname.new "_site/#{pn_web}"
  if pn.exist?
    %Q|<a href="#{pn_web.to_s}"><tt>#{diffstat(pn).gsub(" ", "&nbsp;")}</tt></a>|
  else
    "<tt>0</tt>"
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

variables[:lastmod] = DateTime.now.strftime("%B %-d, %Y")
variables[:html_table] = generate_html_table(data)

res = ERB.new(erb_str, trim_mode: ">").result(variables.instance_eval { binding })

File.open(html_file, 'w') do |f|
  f.write(res)
end

FileUtils.cp "header.png", "_site/wise_papa_sloth_corrupted_by_his_own_power_can_no_leader_go_untainted.png"
FileUtils.cp "homebrew.html", "_site/homebrew.html"
