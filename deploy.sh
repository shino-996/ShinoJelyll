#!/bin/sh
bundle exec jekyll clean
bundle exec jekyll build
cd _site
git init
git remote add jekyll root@shino.space:jekyll.git
git add .
commit_time=$(date "+%Y-%m-%d %H:%M:%S")
git commit -m "${commit_time}"
git push -f jekyll master
cd ../
rm -rf _site
git add .
git commit -m "$1"
git push