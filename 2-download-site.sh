#!/bin/sh

head -n200 data.csv | parallel --delay 10 --retries 3 --csv --skip-first-line -j2 bundle exec wayback_machine_downloader {1} --exact-url --all-timestamps
