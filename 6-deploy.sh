#!/bin/bash

cd _site
git init
git config user.name 'Jonathan Chang'
git config user.email 'me@jonathanchang.org'
git add .
git commit -m 'deploy'
git remote add deploy git@github.com:jonchang/wanderinginn.neocities.org.git
git push --force deploy master:gh-pages
rm -rf .git
cd ..
