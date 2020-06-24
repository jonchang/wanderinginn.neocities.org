#!/bin/sh

head -n21 data.csv | tail -n20 | parallel --delay 10 --csv -j4 bundle exec wayback_machine_downloader {1} --exact-url --all-timestamps
