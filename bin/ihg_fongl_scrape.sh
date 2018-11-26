#!/bin/bash

# The command call should be...
# ./ihg_fongl_scrape.sh [user_name] [password] [output_file]

url="https://ihg-client.ucsf.edu/fongl/"

echo "### Crawling ${url} website... ###"
sleep 2s
echo "### This will take some time to finish, please wait. ###"

wget \
  --recursive \
  --level=inf \
  --spider \
  --server-response \
  --no-directories \
  --output-file="${3}" "$@" \
  --limit-rate=20m \
  --user="${1}" \
  --password="${2}" \
  "$url"

echo "Finished with crawling!"
sleep 1s
