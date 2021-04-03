.POSIX:

help: ## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | sed -e 's/\(\:.*\#\#\)/\:\ /' | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

site: _site/diffs _site/index.html ## Generate the website

download: websites ## Force a re-download of history from the Internet Archive

Gemfile.lock: Gemfile ## Install bundler gems
	bundle install
	touch $@

RUBY_FILES := $(wildcard *.rb)

$(RUBY_FILES): Gemfile.lock

data.csv: 1-parse-diffs.rb ## Update data from sitemap.xml
	bundle exec ruby $<
	touch $@

websites: 2-download-site.sh data.csv ## Download the site
	sh $<
	touch $@

texts: src/main.rs Cargo.toml Cargo.lock websites ## Generate text files using readability
	cargo run --release
	touch $@

diffs: _site/diffs ## Generate diffs with breakerbreaker

_site/diffs: 4-breakbreak.rb texts data.csv diff.html.erb
	bundle exec ruby $<
	touch $@

_site/index.html: 5-generate-site.rb index.html.erb
	bundle exec ruby $<
	touch $@

.PHONY: _site/index.html download
