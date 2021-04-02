#!/bin/bash

set -eu

docker pull ghcr.io/jonchang/wanderinginn-archive:latest
docker run --name temp ghcr.io/jonchang/wanderinginn-archive:latest /bin/true
docker cp temp:all_text.tar.xz .
docker rm temp
tar xf all_text.tar.xz
rm all_text.tar.xz
