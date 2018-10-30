#!/bin/bash

# This will create a scan and hash of a directory.
# The command call should be...
# ./metis_scan.sh [directory] > [output_scan.csv]

while read line; do

  file_data=($line)
  size=${file_data[0]}
  name=${file_data[1]}

  if ! [[ \
    $name == *"/"  || \
    $name == *"?C=M;O=D" || \
    $name == *"?C=M;O=A" || \
    $name == *"?C=N;O=D" || \
    $name == *"?C=N;O=A" || \
    $name == *"?C=S;O=D" || \
    $name == *"?C=S;O=A" || \
    $name == *"?C=D;O=D" || \
    $name == *"?C=D;O=A" \
  ]]; then
    sum="$(md5sum $name 2>/dev/null)"
    sum=${sum%% *}     # Strip off filename to get sum only.
    echo "$size,$name,$sum"
  fi
done <<<"$(find $1 -type f -printf "%s %p\n")"
