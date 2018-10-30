#!/bin/bash

# This will clean up the old metis scan files. This script won't be required in
# the future.
#
# The command call should be...
# ./metis_clean.sh [input_file] > output_file.csv

while IFS=$'\t' read -r -a p ;
do
  if ! [[ \
    ${p[1]} == *"/"  || \
    ${p[1]} == *"?C=M;O=D" || \
    ${p[1]} == *"?C=M;O=A" || \
    ${p[1]} == *"?C=N;O=D" || \
    ${p[1]} == *"?C=N;O=A" || \
    ${p[1]} == *"?C=S;O=D" || \
    ${p[1]} == *"?C=S;O=A" || \
    ${p[1]} == *"?C=D;O=D" || \
    ${p[1]} == *"?C=D;O=A" || \
    ${p[1]} == *"index.html" \
  ]]; then
    printf "%s,%s,\n" "${p[0]}" "${p[1]}"
  fi
done < "$1"
