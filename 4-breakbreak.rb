#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'parallel'
require 'ruby-progressbar'
require 'diffy'
require 'csv'
require 'ostruct'

def slug_from_fn(filename)
  filename =~ %r{([\w-]+)/(\d{14})}
  slug = Regexp.last_match(1)
  datestamp = Regexp.last_match(2)
  [slug, datestamp]
end

# https://news.ycombinator.com/item?id=13997533
def breakerbreaker(text)
  text.gsub! "\u00A0", ' '
  text.gsub!(/([.,?!:;)'"–…]) /, "\\1 \n")
  text.gsub '…', "…\n"
end

# Create a bit of spacing between each "chunk"
def tweak_diffy_html(html)
  html.lines.map do |line|
    case line
    when /class="diff-block-info"/
      "</ul>\n<ul>\n"
    when /class="diff-comment"/ then nil
    when %r{<span></span>} then nil
    else
      line
    end
  end.compact.join
end

data = CSV.read('data.csv', headers: true, header_converters: :symbol)

df = {}

data.each do |row|
  df[row[:slug]] = {
    wordpress_date: row[:post_date],
    wordpress_title: row[:title],
    wordpress_url: row[:url]
  }
end

FileUtils.mkdir_p '_site/diffs'
FileUtils.mkdir_p '_site/texts'

texts = Dir['texts/*/'].sort

erb_text = File.read('diff.html.erb')

Parallel.each(texts, in_processes: 4, progress: 'Diffing') do |dir|
  texts = Dir["#{dir}*"].sort
  aa = texts.first
  bb = texts.last
  slug_a, date_a = slug_from_fn aa
  slug, date_b = slug_from_fn bb
  raise unless slug_a == slug

  File.open("_site/texts/#{slug}.txt", 'w') { |f| f.write(File.open(bb).read) }
  next if texts.length < 2

  broke_a = breakerbreaker File.open(aa).read
  broke_b = breakerbreaker File.open(bb).read
  diff_html = Diffy::Diff.new(broke_a, broke_b, context: 1, include_diff_info: true).to_s(:html)

  next if diff_html =~ %r{<div class="diff"></div>}

  diff_html = tweak_diffy_html(diff_html)

  variables = OpenStruct.new
  variables[:diff_html] = diff_html
  variables[:title] = df[slug][:wordpress_title]
  variables[:wp_url] = df[slug][:wordpress_url]
  variables[:back_link] = "/#chapter-#{slug}"
  res = ERB.new(erb_text, trim_mode: '>').result(variables.instance_eval { binding })

  File.open("_site/diffs/#{slug}.html", 'w') { |f| f.write(res) }
end
