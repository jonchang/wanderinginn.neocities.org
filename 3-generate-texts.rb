#!/usr/bin/env ruby

require 'readability'
require 'fileutils'
require 'parallel'
require 'ruby-progressbar'

# parallel --csv -P4 --delay 10 wayback_machine_downloader {1} --exact-url --all-timestamps :::: data.csv
#

files = Dir['websites/**/index.html'].sort

Parallel.each(files, in_processes: 4, progress: 'Parsing') do |f|
    src = open(f).read
    datestamp = f[%r{\d{14}}]
    f =~ %r{/([\w-]+)/index\.html$}
    slug = Regexp.last_match(1)
    txt = Readability::Document.new(src).content
    next if txt =~ /This post is password protected/
    txt.gsub! %r{(?:</?div>|</p>|(?:Next|Previous) Chapter)}, ""
    txt.gsub! /(?:<p>|\R)/, "\n\n"
    txt.gsub! "\u00A0", " "
    txt.gsub! /[ \t]+\n/, "\n"
    txt.gsub! /\n{3,}/, "\n\n"
    txt.strip!
    FileUtils.mkdir_p "texts/#{slug}"
    open("texts/#{slug}/#{datestamp}.txt", "w") do |xx|
        xx.puts txt
    end
end
