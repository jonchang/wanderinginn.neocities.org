#!/usr/bin/env ruby

require 'fileutils'
require 'parallel'
require 'ruby-progressbar'
require 'diffy'

def slug_from_fn(fn)
    fn =~ %r{([\w-]+)/(\d{14})}
    slug = Regexp.last_match(1)
    datestamp = Regexp.last_match(2)
    return slug, datestamp
end

# https://news.ycombinator.com/item?id=13997533
def breakerbreaker(text)
    text.gsub! %r{([.,?!:;)'"–…]) }, "\\1 \n"
    text.gsub "…", "…\n"
end

FileUtils.mkdir_p "_site/diffs"
open("_site/diffs/diff.css", "w") do |f|
    f.puts Diffy::CSS
end

texts = Dir['texts/*/'].sort

Parallel.each(texts, in_processes: 4, progress: 'Diffing') do |dir|
    texts = Dir["#{dir}*"].sort
    next if texts.length < 2
    aa = texts.first
    bb = texts.last
    slug, date_a = slug_from_fn aa
    slug, date_b = slug_from_fn bb
    broke_a = breakerbreaker open(aa).read
    broke_b = breakerbreaker open(bb).read
    diff_html = Diffy::Diff.new(broke_a, broke_b, :context => 2).to_s(:html)
    next if diff_html =~ %r{<div class="diff"></div>}
    open("_site/diffs/#{slug}.html", "w") do |f|
        f.puts '<link rel="stylesheet" href="diff.css"/>'
        f.puts diff_html
    end
end
