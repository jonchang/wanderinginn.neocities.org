#!/usr/bin/env ruby
# frozen_string_literal: true

require 'find'
require 'net/http'
require 'uri'
require 'csv'
require 'json'

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
  to_update << row[:url] if acc[slug] < datetime
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
  url = url.sub(%r{https?://}, '').gsub(%r{/$}, '')

  next if url == always_skip

  request = Net::HTTP::Post.new(api_url.request_uri)
  request.set_form_data({ 'url' => url })
  request['accept'] = 'application/json'
  request['cookie'] = ENV['INTERNET_ARCHIVE_COOKIE']

  # IA has very aggressive rate limiting.
  response = http.request(request)
  if response.body =~ /429 Too Many Requests/
    sleep 30
    redo
  end

  json = JSON.parse(response.body)
  if json['message']
    puts "#{url} => #{json['message']}"
    if json['message'] =~ /You have already reached the limit of active sessions/
      sleep 30
      redo
    end
  else
    puts "#{url} => #{json['job_id']}"
  end

  sleep 2
end
