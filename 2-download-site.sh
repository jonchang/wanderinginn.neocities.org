#!/bin/sh

head -n21 data.csv | parallel --delay 10 --csv --skip-first-line -j4 bundle exec wayback_machine_downloader {1} --exact-url --all-timestamps
