# wanderinginn.neocities.org

This hosts code for a website geared towards tracking changes on another website.

## Setup

```sh
bundle install
brew install parallel cpanm
cpanm -i Text::CSV
```

## Building

```
make help

make download
make site
```

## Updating

When new texts are publicly released, or old texts are updated, inform the Internet Archive of the new changes by visiting <https://web.archive.org/save/> and saving a current copy of the link.

It used to be the case that directly using something like `curl -L https://web.archive.org/save/https://example.com` was sufficient, but this has had intermittent problems and thus visiting the Internet Archive in a browser is necessary.

## Contributing

I am unlikely to entertain suggestions for features, unless these come in the form of a good pull request. Any pull request that increases the amount of manual work for me probably won't be merged.

## Copyright

This repository does not redistribute the full text of the original work as the original is still under copyright. This code and website does not infringe on the original work's copyright due to fair use rights, as this work:

* creates a transformative reference work using the original text,
* is based on a published text,
* reproduces less than 2% of the original (`percent-usage.sh`), and
* is noncommercial and is unlikely to affect the market for the original text.

There is also an explicit grant of permissions from the author:

> You may not use any copyrighted materials, including interior art and text, from my books or website.
> There are two exceptions to the above rule:
> [...] when they are used for non-commercial or promotional purposes for fan websites, fan conventions, and scholarly, web-based endeavors like podcasts.

In addition, archival copies of the text are obtained from the Internet Archive, which is permitted to distribute full texts of copyrighted works as it is a library.

Code and text not related to the original work is licensed under the MIT license.
