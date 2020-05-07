#!/usr/bin/env ruby

require "open-uri"
require "time"
require "csv"

require "nokogiri"

def date_from_url(url)
  url = url.gsub "https://wanderinginn.com/", ""
  begin
    DateTime.parse url[%r{\d+/\d+/\d+}]
  rescue TypeError
    nil
  end
end

def slug_from_url(url)
  url[%r{[\w-]+/$}].chomp("/")
end

doc = URI.open("https://wanderinginn.com/table-of-contents/") { |f| Nokogiri::HTML(f) }
doc.remove_namespaces!
entry = doc.css(".entry-content").first
title_map = entry.css("a").map do |url|
  [url["href"].gsub(%r{/+$}, ""), url.text.strip]
end.to_h

doc = URI.open("https://wanderinginn.com/sitemap.xml") { |f| Nokogiri::XML(f) }
doc.remove_namespaces!

url_mapping = doc.xpath(".//url").map do |url|
  [url.xpath("./loc").text, DateTime.parse(url.xpath("./lastmod").text)]
end

CSV.open("data.csv", "wb") do |csv|
  csv << %w[url title slug mod_datetime post_date diff]

  url_mapping.each do |url, last_modified|
    post_date = date_from_url url
    next unless post_date
    diff = last_modified - post_date
    title = title_map[url.gsub(%r{/+$}, "")]
    slug = slug_from_url(url)
    csv << [url, title, slug, last_modified, post_date, diff.to_i]
  end
end
