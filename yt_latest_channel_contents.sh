#!/bin/bash

LANG=ja_JP.utf8

# Usage
show_usage() {
  cat << _EOT_
Require:
  youtube-dl (see https://github.com/ytdl-org/youtube-dl/)
Usage: $(basename "$0") [options]
  example
  ./yt_latest_channel_contents.sh -c UCOyPw9GOLDTk0PxBeOkldtw -o snd.m4a
Options:
  -c ChannelId
  -o FILEPATH Output file path
_EOT_
}

# Define argument values
channel_id=
output=

# Argument none?
if [ $# -lt 1 ]; then
  show_usage
  exit 1
fi

# Parse argument
while getopts c:o: option; do
  case "${option}" in
    c)
      channel_id="${OPTARG}"
      ;;
    o)
      output="${OPTARG}"
      ;;
    \?)
      show_usage
      exit 1
      ;;
  esac
done

# Check argument parameter
if [ -z "${channel_id}" ]; then
  # -s value is empty
  echo "Require \"Channel ID\"" >&2
  exit 1
fi
if [ -z "${output}" ]; then
  # -o value is empty
  echo "Require \"Output file Path\"" >&2
  exit 1
fi

youtube-dl -f 140 "https://www.youtube.com/watch?v=`python latest_video_id.py $channel_id`" -o $output
