#!/bin/sh
create_time=$(date "+%Y-%m-%d %H:%M:%S")
create_date=$(date "+%Y-%m-%d")
echo "---\ntitle: $1\ndate: ${create_date} +0800\ntags: \n---" > ${create_date}-$1.md