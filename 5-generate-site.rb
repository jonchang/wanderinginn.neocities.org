#!/usr/bin/env ruby

require "erb"
require "ostruct"
require 'csv'

data = CSV.read("data.csv", headers: true, header_converters: :symbol)

data = data.sort { |a, b| a[0] <=> b[0] }
data = data.uniq { |c| c[:post_date] }

erb_file = "index.html.erb"
html_file = "_site/" + File.basename(erb_file, ".erb") #=>"index.html"

erb_str = File.read(erb_file)

variables = OpenStruct.new

def generate_chapter_link(row)
    %Q|<a name="chapter-#{row[:slug]}" href="#{row[:url]}">#{row[:title]}</a>|
end

def generate_diff_link(row)
  pn_web = "diffs/#{row[:slug]}.html"
  pn = Pathname.new "_site/#{pn_web}"
  size = pn.size?
  if size
    %Q|<a href="#{pn_web.to_s}">#{size}</a>|
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

variables[:lastmod] = DateTime.now.strftime("%B %d, %Y")
variables[:html_table] = generate_html_table(data)

res = ERB.new(erb_str, trim_mode: ">").result(variables.instance_eval { binding })

File.open(html_file, 'w') do |f|
  f.write(res)
end
