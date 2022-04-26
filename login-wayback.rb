#!/usr/bin/env ruby
# frozen_string_literal: true

# Logs in to the Internet Archive using a username and password from the macOS keychain.
# Sets the IA login cookie on GitHub Actions as an encrypted secret.

require 'net/http'
require 'uri'
require 'json'
require 'open3'

INTERNET_ARCHIVE_USER = `security find-internet-password -s archive.org`.match(/"acct".+"([\w.]+@[\w.]+)"/)[1]
INTERNET_ARCHIVE_PASS = `security find-internet-password -s archive.org -w`.chomp
API_URL = URI.parse('https://archive.org/account/login')

# With a Net::HTTPResponse class, parse the Set-Cookie response headers and return something
# that can be sent in the Cookie: request header.
def parse_cookies(response)
  response.get_fields('set-cookie').reject { |e| e.include? 'deleted' }.map { |e| e.match(/^([^;]+);/)[1] }.join('; ')
end

http = Net::HTTP.new(API_URL.host, API_URL.port)
http.use_ssl = true

# Fake a login to Internet Archive. We need to first make a GET request to fetch the ia-auth cookie, then
# pass that back to the login endpoint with POST.
cookie_jar = nil
http.request_get(API_URL) do |response|
  cookie_jar = parse_cookies(response)
end

# POST a login, setting cookies and form data where necessary.
request = Net::HTTP::Post.new(API_URL.request_uri, { 'cookie' => cookie_jar })

# From watching browser requests.
request.set_form_data(
  {
    'username' => INTERNET_ARCHIVE_USER,
    'password' => INTERNET_ARCHIVE_PASS,
    'remember' => 'true',
    'referer' => 'https://archive.org/',
    'submit_by_js' => 'true',
    'login' => 'true'
  }
)

request['accept'] = 'application/json'
response = http.request(request)

# We should get back a "logged-in-sig" cookie!
cookie_jar = parse_cookies(response)

raise unless cookie_jar.include? 'logged-in-sig='

# Set using GitHub CLI. Too complicated to directly hit the API since it requires libsodium to encrypt
cmd = %w[gh secret set INTERNET_ARCHIVE_COOKIE -R jonchang/wanderinginn.neocities.org --app actions]

Open3.popen2e(*cmd) do |stdin, stdout_and_stderr, wait_thr|
  stdin.puts cookie_jar
  stdin.close_write
  stdout_and_stderr.each_line { |l| puts l }
  stdout_and_stderr.close
  wait_thr.value
end

puts `gh secret list -R jonchang/wanderinginn.neocities.org`
