#!/bin/sh
# Radiko recorder
set -u

LANG=ja_JP.utf8

# Usage
show_usage() {
  cat << _EOT_
Usage: $(basename "$0") [options]
  example
  ./download_contents.sh -s TBS -n title -v "JUNK 伊集院光・深夜の馬鹿力" -o out.m4a
  ./download_contents.sh -s LFR -n url -v "https://www.allnightnippon.com/nn/" -o out.m4a
  ./download_contents.sh -s TBS -n pfm -v "赤江珠緒/カンニング竹山" -o out.mp3 -x
  ./download_contents.sh -s INT -p 'Dave Fromm, Ali Morizumi' -t 'The Dave Fromm Show, Hour 1' -o out.m4a
Options:
  -s STATION  Station ID (see http://radiko.jp/v3/station/region/full.xml)
  -n NODE     Node name  (see http://radiko.jp/v3/program/station/weekly/{STATION}.xml)
  -v VALUE    Node value (see http://radiko.jp/v3/program/station/weekly/{STATION}.xml)
  -o FILEPATH Output file path
  -x without param -bsf:a aac_adtstoasc -acodec copy in ffmpeg
_EOT_
}

# Define argument values
station_id=
node=
value=
pfm=
title=
output=
aac="-bsf:a aac_adtstoasc -acodec copy"
# Argument none?
if [ $# -lt 1 ]; then
  show_usage
  exit 1
fi

# Parse argument
while getopts s:n:v:o:p:t:x option; do
  case "${option}" in
    s)
      station_id="${OPTARG}"
      ;;
    n)
      node="${OPTARG}"
      ;;
    v)
      value="${OPTARG}"
      ;;
    o)
      output="${OPTARG}"
      ;;
    p)
      pfm="${OPTARG}"
      ;;
    t)
      title="${OPTARG}"
      ;;
    x)
      aac=""
      ;;
    \?)
      show_usage
      exit 1
      ;;
  esac
done

# Check argument parameter
if [ -z "${station_id}" ]; then
  # -s value is empty
  echo "Require \"Station ID\"" >&2
  exit 1
fi
if test -z "${pfm}" -a -z "${title}" ; then
  if [ -z "${node}" ]; then
    # -f value is empty
    echo "Require \"XMLPath target node\"" >&2
    exit 1
  fi
  if [ -z "${value}" ]; then
    # -t value is empty
    echo "Require \"XMLPath target value\"" >&2
    exit 1
  fi
fi

if [ -z "${output}" ]; then
  # -o value is empty
  echo "Require \"Output file Path\"" >&2
  exit 1
fi

if test -z "${pfm}" -a -z "${title}" ; then
  fromtime=`xmllint http://radiko.jp/v3/program/station/weekly/${station_id}.xml --xpath "//${node}[contains(text(), '${value}') and not(.=preceding::${node})]/parent::node()/@ft" | sed -e 's/ ft="//' | sed -e 's/00"//' | cut -d" " -f1`
  totime=`xmllint http://radiko.jp/v3/program/station/weekly/${station_id}.xml --xpath "//${node}[contains(text(), '${value}') and not(.=preceding::${node})]/parent::node()/@to" | sed -e 's/ to="//' | sed -e 's/00"//' | cut -d" " -f1`
  program_id=`xmllint http://radiko.jp/v3/program/station/weekly/TBS.xml --xpath "//url[contains(text(), '${value}') and not(.=preceding::url)]/parent::node()/@id" | sed -e "s/ id=//"`
  echo "detected programId : ${program_id} / ${fromtime}~${totime}"
else
  fromtime=`xmllint http://radiko.jp/v3/program/station/weekly/${station_id}.xml --xpath "(//prog[title[contains(text(), '${title}')] and pfm[contains(text(), '${pfm}')]])[1]/@ft" | sed -e 's/ ft="//' | sed -e 's/00"//' | cut -d" " -f1`
  totime=`xmllint http://radiko.jp/v3/program/station/weekly/${station_id}.xml --xpath "(//prog[title[contains(text(), '${title}')] and pfm[contains(text(), '${pfm}')]])[1]/@to" | sed -e 's/ to="//' | sed -e 's/00"//' | cut -d" " -f1`
  program_id=`xmllint http://radiko.jp/v3/program/station/weekly/${station_id}.xml --xpath "(//prog[title[contains(text(), '${title}')] and pfm[contains(text(), '${pfm}')]])[1]/@id" | sed -e "s/ id=//"`
  echo "detected programId : ${program_id} / ${fromtime}~${totime}"
fi

# Authorize 1
auth1_res=$(curl \
    --silent \
    --header "X-Radiko-App: pc_html5" \
    --header "X-Radiko-App-Version: 0.0.1" \
    --header "X-Radiko-Device: pc" \
    --header "X-Radiko-User: radiko_user" \
    --dump-header - \
    --output /dev/null \
    "https://radiko.jp/v2/api/auth1")

# Get partial key
authtoken=$(echo "${auth1_res}" | awk 'tolower($0) ~/^x-radiko-authtoken: / {print substr($0,21,length($0)-21)}')
keyoffset=$(echo "${auth1_res}" | awk 'tolower($0) ~/^x-radiko-keyoffset: / {print substr($0,21,length($0)-21)}')
keylength=$(echo "${auth1_res}" | awk 'tolower($0) ~/^x-radiko-keylength: / {print substr($0,21,length($0)-21)}')

if [ -z "${authtoken}" ] || [ -z "${keyoffset}" ] || [ -z "${keylength}" ]; then
  echo "auth1 failed" >&2
  exit 1
fi
echo "processed auth1"

AUTHKEY_VALUE="bcd151073c03b352e1ef2fd66c32209da9ca0afa"
partialkey=$(echo "${AUTHKEY_VALUE}" | dd bs=1 "skip=${keyoffset}" "count=${keylength}" 2> /dev/null | base64)

# Authorize 2
curl \
    --silent \
    --header "X-Radiko-Device: pc" \
    --header "X-Radiko-User: radiko_user" \
    --header "X-Radiko-AuthToken: ${authtoken}" \
    --header "X-Radiko-PartialKey: ${partialkey}" \
    --output /dev/null \
    "https://radiko.jp/v2/api/auth2"
ret=$?

if [ ${ret} -ne 0 ]; then
  echo "auth2 failed" >&2
  exit 1
fi
echo "processed auth2"

# Record
ffmpeg \
    -loglevel error \
    -fflags +discardcorrupt \
    -headers "X-Radiko-Authtoken: ${authtoken}" \
    -i "https://radiko.jp/v2/api/ts/playlist.m3u8?station_id=${station_id}&l=15&ft=${fromtime}00&to=${totime}00" \
    -vn \
    -y \
    ${aac} "${output}"
ret=$?

if [ ${ret} -ne 0 ]; then
  echo "Record failed" >&2
  exit 1
fi
echo "done"

# Finish
exit 0
