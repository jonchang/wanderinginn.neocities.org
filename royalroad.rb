#!/usr/bin/env ruby

require 'open-uri'
require 'time'
require 'csv'
require 'nokogiri'
require 'fileutils'
require 'parallel'
require 'ruby-progressbar'

data = CSV.read("data.csv", headers: true, header_converters: :symbol)

df = {}

data.each do |row|
  df[row[:slug]] = {
    wordpress_date: row[:post_date],
    wordpress_title: row[:title],
    wordpress_url: row[:url]
  }
end

royal_road_mapping = CSV.read("royalroad.csv", headers: true, header_converters: :symbol, col_sep: "\t")

df_rr = {}

royal_road_mapping.each do |row|
  df_rr[row[:royal_road_title]] = row[:slug]
end

doc = URI.open("https://www.royalroad.com/fiction/10073/the-wandering-inn") { |f| Nokogiri::HTML(f) }
doc.remove_namespaces!
chapters = doc.css("#chapters a[href^='/fiction/'][href*='/chapter/']")
times = doc.css("#chapters a[class^='/fiction/'][class*='/chapter/'] time")

def to_archive_timestamp(dt)
  dt.strftime("%Y%m%d%H%M%S")
end

def wp_path(url)
  url.gsub("https://wanderinginn.com/", "")[%r{\d{4}/\d{2}/\d{2}}]
end

Parallel.each(chapters.zip(times), in_processes: 4, progress: "Downloading") do |chap, time|
  title = chap.text.strip
  slug = df_rr[title]
  url = "https://www.royalroad.com" + chap.attr("href")
  timestamp = DateTime.parse(time.attr("title"))
  df[slug][:royal_road_time] = timestamp
  df[slug][:royal_road_url] = url
  path = "websites/royalroad.com/#{to_archive_timestamp(timestamp)}/#{slug}/"
  FileUtils.mkdir_p path
  open(path + "index.html", "wb") do |f|
    f << URI.open(url).read
  end
end
