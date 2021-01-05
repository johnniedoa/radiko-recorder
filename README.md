### Required

ffmpeg libxml2-utils mp3splt youtube-dl

### download_contents.sh

ラジコのタイムフリーコンテンツを保存するスクリプトです。以下のように使います。
CMをカットするスクリプト（mp3spltを使用）にわたすフォーマットがmp3であるため、パラメータに`-x`を指定してmp3ファイルを保存することができます。

```
Usage:
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
```

### cut_commercial.sh

ラジコのコンテンツのCMをカットするスクリプトです。以下のように使います。
コンテンツの無音部分を検知しファイルを分割します。分割されたファイルのサイズを見てCMを判断します。

```
Usage:
  example
  ./cut_commercial.sh -i out.mp3 -s 786432
Options:
  -i input file
  -s file size byte
```

### yt_latest_channel_contents.sh

youtubeのチャンネルの最新のコンテンツを保存するスクリプトです。以下のように使います。
latest_video_id.pyにてYouTube Data APIを使用するためDEVELOPER_KEYが別途必要になります。

```
Require:
  youtube-dl (see https://github.com/ytdl-org/youtube-dl/)
  Set DEVELOPER_KEY to the API key value from the APIs & auth > latest_video_id.py
Usage: $(basename "$0") [options]
  example
  ./yt_latest_channel_contents.sh -c UCOyPw9GOLDTk0PxBeOkldtw -o snd.m4a
Options:
  -c ChannelId
  -o FILEPATH Output file path
```

