#!/usr/bin/env ruby

require 'find'
require 'net/http'
require 'uri'
require 'csv'

# For everything in websites/wanderinginn.com, generate a map between the slug and last archive time.
acc = Hash.new(0)
Find.find('websites/wanderinginn.com') do |fn|
  next unless File.file? fn

  fn =~ %r{(\d{14})/\d{4}/\d{2}/\d{2}/([\w-]+)}

  time = Regexp.last_match(1).to_i
  slug = Regexp.last_match(2)

  acc[slug] = time if acc[slug] < time
end

# Get a list of things to update, if the archive time is less than the last updated time.
to_update = []
data = CSV.read('data.csv', headers: true, header_converters: :symbol)
data.each do |row|
  # Wordpress format looks like 2021-04-02T17:11:22+00:00
  # Delete everything after `+` and remove all nonnumeric characters
  datetime = row[:mod_datetime].gsub('+00:00', '').gsub(/\D/, '').to_i
  slug = row[:slug]
  if acc[slug] < datetime
    to_update << row[:url]
  end
end

# Execute a POST request against the wayback API. Reverse engineered from
# https://github.com/internetarchive/wayback-machine-webextension/
# FIXME: This API requires authentication. Encode as a secret?
puts "#{to_update.size} URLs to ping..."

uri = URI.parse('https://web.archive.org/save/')

to_update.each do |url|
  puts url
  # http = Net::HTTP.new(uri.host, uri.port)
  # http.use_ssl = true

  # request = Net::HTTP::Post.new(uri.request_uri)
  # request.set_form_data({"url" => URI.encode_www_form_component(url)})
  # request['accept'] = 'application/json'

  # response = http.request(request)

  # puts response.to_hash.inspect
  # puts response.body
  # sleep 3
end
