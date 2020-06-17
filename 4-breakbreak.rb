#!/usr/bin/env ruby

require 'fileutils'
require 'parallel'
require 'ruby-progressbar'
require 'diffy'
require 'csv'
require 'ostruct'

def slug_from_fn(fn)
  fn =~ %r{([\w-]+)/(\d{14})}
  slug = Regexp.last_match(1)
  datestamp = Regexp.last_match(2)
  return slug, datestamp
end

data = CSV.read("data.csv", headers: true, header_converters: :symbol)

df = {}

data.each do |row|
  df[row[:slug]] = {
    wordpress_date: row[:post_date],
    wordpress_title: row[:title],
    wordpress_url: row[:url]
  }
end

# https://news.ycombinator.com/item?id=13997533
def breakerbreaker(text)
  text.gsub! "\u00A0", " "
  text.gsub! %r{([.,?!:;)'"–…]) }, "\\1 \n"
  text.gsub "…", "…\n"
end

FileUtils.mkdir_p "_site/diffs"
FileUtils.mkdir_p "_site/texts"

open("_site/diffs/diff.css", "w") do |f|
  f.puts Diffy::CSS
end

texts = Dir['texts/*/'].sort

erb_text = File.read("diff.html.erb")

Parallel.each(texts, in_processes: 4, progress: 'Diffing') do |dir|
  texts = Dir["#{dir}*"].sort
  next if texts.length < 2
  aa = texts.first
  bb = texts.last
  slug, date_a = slug_from_fn aa
  slug, date_b = slug_from_fn bb
  File.open("_site/texts/#{slug}.txt", "w") do |f|
    f.write(open(bb).read)
  end
  broke_a = breakerbreaker open(aa).read
  broke_b = breakerbreaker open(bb).read
  diff_html = Diffy::Diff.new(broke_a, broke_b, :context => 2).to_s(:html)
  next if diff_html =~ %r{<div class="diff"></div>}

  variables = OpenStruct.new
  variables[:diff_html] = diff_html
  variables[:title] = df[slug][:wordpress_title]
  variables[:wp_url] = df[slug][:wordpress_url]
  variables[:back_link] = "/#chapter-#{slug}"
  res = ERB.new(erb_text, trim_mode: ">").result(variables.instance_eval { binding })

  File.open("_site/diffs/#{slug}.html", "w") do |f|
    f.write(res)
  end
end
