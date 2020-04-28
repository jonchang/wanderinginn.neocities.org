# Wandering inn site


## Setup
```sh
bundle install
brew install parallel cpanm
cpanm -i Text::CSV
```

## Running

```
bundle exec ./1-parse_diffs.rb
./2-download_site.sh
bundle exec ./3-generate_texts.rb
bundle exec ./4-breakbreak.rb
bundle exec ./5-generate-site.rb
./6-deploy.sh
```
