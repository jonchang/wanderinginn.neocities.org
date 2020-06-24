#!/bin/sh

parallel --csv -j4 --delay 10 bundle exec wayback_machine_downloader {1} --exact-url --all-timestamps ::: $(head -n21 data.csv | tail -n20)
