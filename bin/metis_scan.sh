#!/bin/bash

# This will create a scan and hash of a directory.
# The command call should be...
# ./metis_scan.sh [directory] > [output_scan.csv]

while read line; do
  file_data=($line)
  size=${file_data[0]}
  name=${file_data[1]}
  sum="$(md5sum $name 2>/dev/null)"
  sum=${sum%% *}     # Strip off filename to get sum only.
  echo "$size,$name,$sum"
done <<<"$(find $1 -type f -printf "%s %p\n")"
