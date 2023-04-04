#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open-uri'
require 'time'
require 'csv'

require 'nokogiri'

VOLUME_DATES = {
  'Volume 1' => Date.new(2017, 3, 2),
  'Volume 1 (rewrite)' => Date.new(2017, 3, 6),
  'Volume 2' => Date.new(2017, 7, 30),
  'Volume 3' => Date.new(2017, 12, 31),
  'Volume 4' => Date.new(2018, 7, 9),
  'Volume 5' => Date.new(2019, 3, 3),
  'Volume 6' => Date.new(2020, 1, 2),
  'Volume 7' => Date.new(2020, 12, 24),
  'Volume 8' => Date.new(2022, 6, 1),
  'Volume 9' => Date.new(2024, 1, 1)
}.freeze

SLUGS_TO_SKIP = %w[
  8-11-e
  8-49-m-unedited
  gravesong
  the-wandering-inn-ama
].freeze

def date_from_url(url)
  url = url.gsub 'https://wanderinginn.com/', ''
  begin
    Date.parse url[%r{\d+/\d+/\d+}]
  rescue TypeError
    nil
  end
end

def slug_from_url(url)
  url[%r{[\w-]+/$}].chomp('/')
end

def guess_title(url)
  puts "Guessing title for #{url}"
  doc = URI.parse(url).open { |f| Nokogiri::HTML(f) }
  doc.remove_namespaces!
  title = doc.css('title').first
  title.text.gsub('| The Wandering Inn', '').strip
end

doc = URI.open('https://wanderinginn.com/table-of-contents/') { |f| Nokogiri::HTML(f) }
doc.remove_namespaces!
entry = doc.css('.entry-content').first
title_map = entry.css('a').map do |url|
  [url['href'].gsub(%r{/+$}, ''), url.text.strip]
end.to_h

doc = URI.open('https://wanderinginn.com/sitemap-1.xml') { |f| Nokogiri::XML(f) }
doc.remove_namespaces!

url_mapping = doc.xpath('.//url').map do |url|
  [url.xpath('./loc').text, DateTime.parse(url.xpath('./lastmod').text)]
end

# sort by last modified
url_mapping.sort_by! { |obj| obj[1] }
url_mapping.reverse!

CSV.open('data.csv', 'wb') do |csv|
  csv << %w[url title slug mod_datetime post_date diff volume]

  url_mapping.each do |url, last_modified|
    post_date = date_from_url url
    next unless post_date

    diff = last_modified - post_date
    title = title_map[url.gsub(%r{/+$}, '')] || guess_title(url)
    slug = slug_from_url(url)

    next if SLUGS_TO_SKIP.include? slug

    volume = VOLUME_DATES.select { |_, ii| post_date < ii }.keys.first

    csv << [url, title, slug, last_modified, post_date, diff.to_i, volume + 1]
  end
end
