#!/bin/sh
bundle exec jekyll clean
bundle exec jekyll build
cd _site
git init
git remote add jekyll root@shino.space:jekyll.git
git add .
commit_time=$(date "+%Y-%m-%d %H:%M:%S")
git commit -m "${commit_time}"
git push -f jekyll master:master
curl -H 'Content-Type:text/plain' --data-binary @urls.xml "http://data.zz.baidu.com/urls?site=https://shino.space&token=WuSqU4rdbH2n2FIX"
cd ../
rm -rf _site
git add .
git commit -m "$1"
git push origin master:master