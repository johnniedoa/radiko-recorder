#!/bin/sh

LANG=ja_JP.utf8

# Usage
show_usage() {
  cat << _EOT_
Usage: $(basename "$0") [options]
  example
  ./cut_commercial.sh -i out.mp3 -s 786432
Options:
  -i input file
  -s file size byte
_EOT_
}

# Define argument values
output=
size=786432
# Argument none?
if [ $# -lt 1 ]; then
  show_usage
  exit 1
fi

# Parse argument
while getopts i:s: option; do
  case "${option}" in
    i)
      output="${OPTARG}"
      ;;
    s)
      size=${OPTARG}
      ;;
    \?)
      show_usage
      exit 1
      ;;
  esac
done

if [ -d sliced ]; then
  echo "Working directory found."
  rm -rf sliced/*.mp3
else
  mkdir sliced
fi

echo "" > mp3splt.log
echo "" > list.txt

mp3splt -s -p th=-60,min=0.1,trackmin=10 -d sliced $output

for file in `find sliced/*.mp3 -type f`
do
  fsize=`wc -c $file | awk '{print $1}'`
  if [ $fsize -lt $size ]; then
    echo "${file} smaller than $size found."
  else
    echo "file '$file'" >> list.txt
  fi
done

ffmpeg -f concat -safe 0 -i list.txt -c copy -y "${output}"
rm -rf sliced/*.mp3
