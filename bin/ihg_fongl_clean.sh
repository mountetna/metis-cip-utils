#!/bin/bash

# This will clean up the web scrape file generated by 'ihg_fongl_scrape.sh'
# The command call should be...
# ./ihg_fongl_clean.sh [input_file] > [output_file.csv]

url_to_match="https://ihg-client.ucsf.edu/fongl/"
content_length_to_match="Content-Length"
ending_str="broken links"

url_matches=false
length_matches=false

url_str=""
length_str=""

reset_vars() {
  url_matches=false
  length_matches=false
  url_str=""
  length_str=""
}

parse_vars() {

  IFS=" " read -r -a content_length <<< "$1"
  IFS=" " read -r -a url_data <<< "$2"

  if ! [[ ${url_data[2]} == "" ]]; then
    printf "%s," "${content_length[1]}"
    printf "%s," "${url_data[2]#$url_to_match}"
    printf ","
    printf "%s--%s\n" "${url_data[0]}" "${url_data[1]}"
  fi
}

while IFS="" read -r p || [ -n "$p" ]
do

  if [[ $p = *"$ending_str"* ]]; then
    exit 0
  fi

  if [[ $p = *"$url_to_match"* ]]; then
    url_matches=true
    url_str=$p
  fi

  if [[ $p = *"$content_length_to_match"* ]]; then
    length_matches=true
    length_str=$p
  fi

  if [[ $p = "$\n" ]]; then
    reset_vars
  fi

  if [[ $url_matches && $length_str ]]; then

    if ! [[ \
      $url_str == *"/"  || \
      $url_str == *"?C=M;O=D" || \
      $url_str == *"?C=M;O=A" || \
      $url_str == *"?C=N;O=D" || \
      $url_str == *"?C=N;O=A" || \
      $url_str == *"?C=S;O=D" || \
      $url_str == *"?C=S;O=A" || \
      $url_str == *"?C=D;O=D" || \
      $url_str == *"?C=D;O=A" \
    ]]; then
      parse_vars "$length_str" "$url_str"
    fi

    reset_vars
  fi

done < "$1"
