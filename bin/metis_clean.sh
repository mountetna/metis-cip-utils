#!/bin/bash

# This will clean up the old metis scan files. This script won't be required in
# the future.
#
# The command call should be...
# ./metis_clean.sh [input_file] > output_file.csv

while IFS=$'\t' read -r -a tmp ;
do
  printf "%s,%s,\n" "${p[0]}" "${p[1]}"
done < "$1"
