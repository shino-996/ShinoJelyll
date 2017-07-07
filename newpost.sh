#!/bin/sh
create_time=$(date "+%Y-%m-%d %H:%M:%S")
create_date=$(date "+%Y-%m-%d")
echo "---\ntitle: $1\ndate: ${create_time} +0800\ntags: \n---" > ./_posts/${create_date}-$1.md