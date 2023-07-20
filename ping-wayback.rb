#!/usr/bin/env ruby
# frozen_string_literal: true

require 'find'
require 'net/http'
require 'uri'
require 'csv'
require 'json'
require 'date'
require 'resolv-replace'

# For everything in websites/wanderinginn.com, generate a map between the slug and last archive time.
acc = Hash.new(DateTime.new)
Find.find('websites/') do |fn|
  next unless File.file? fn

  fn =~ %r{/(\d{14})/}
  time = DateTime.strptime(Regexp.last_match(1), '%Y%m%d%H%M%S')

  fn =~ %r{/([\w-]+)/index.html}
  slug = Regexp.last_match(1)

  acc[slug] = time if acc[slug] < time
end

# Get a list of things to update, if the archive time is less than the last updated time.
to_update = []
data = CSV.read('data.csv', headers: true, header_converters: :symbol)
data.each do |row|
  datetime = DateTime.strptime(row[:mod_datetime])
  slug = row[:slug]
  url = row[:url].sub(%r{https?://}, '').gsub(%r{/$}, '')
  to_update << url if acc[slug] < datetime
end

# Execute a POST request against the wayback API. Reverse engineered from
# https://github.com/internetarchive/wayback-machine-webextension/
puts "#{to_update.size} URLs to ping..."

# Authentication consists of three cookies, which we accept from the environment
# as a single string. This signature expires after 1 year.
# test-cookie=1
# logged-in-user=EMAIL
# logged-in-sig=SIGNATURE
api_url = URI.parse('https://web.archive.org/save/')

http = Net::HTTP.new(api_url.host, api_url.port)
http.use_ssl = true

# TODO: Centralize this somewhere
always_skip = 'wanderinginn.com/2021/03/07/8-11-e'

to_update.each do |url|
  if url == always_skip || !ENV['INTERNET_ARCHIVE_COOKIE']
    puts "#{url} => skipped"
    next
  end

  request = Net::HTTP::Post.new(api_url.request_uri)
  request.set_form_data({ 'url' => url })
  request['accept'] = 'application/json'
  request['cookie'] = ENV['INTERNET_ARCHIVE_COOKIE']

  # IA has very aggressive rate limiting.
  response = http.request(request)
  if response.body =~ /429 Too Many Requests/
    sleep 60
    redo
  end

  json = JSON.parse(response.body)
  if json['message']
    puts "#{url} => #{json['message']}"
    if json['message'] =~ /You have already reached the limit of active Save Page Now sessions/
      sleep 60
      redo
    end
  else
    puts "#{url} => #{json['job_id']}"
  end

  sleep 5
end
