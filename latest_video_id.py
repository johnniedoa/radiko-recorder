#!/usr/bin/python
# -*- coding: utf-8 -*-

from apiclient.discovery import build
from apiclient.errors import HttpError
from oauth2client.tools import argparser
import subprocess


# Set DEVELOPER_KEY to the API key value from the APIs & auth > Registered apps
# tab of
#   https://cloud.google.com/console
# Please ensure that you have enabled the YouTube Data API for your project.
DEVELOPER_KEY = "<add your developer key>"
YOUTUBE_API_SERVICE_NAME = "youtube"
YOUTUBE_API_VERSION = "v3"

def youtube_search(options):
  youtube = build(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION,
    developerKey=DEVELOPER_KEY)

  # Call the search.list method to retrieve results matching the specified
  # query term.
  search_response = youtube.search().list(
    part="id",
    maxResults=1,
    channelId=options.channelId,
    order="date",
    q=options.q
  ).execute()

  videos = []
  channels = []
  playlists = []

  # Add each result to the appropriate list, and then display the lists of
  # matching videos, channels, and playlists.
  for search_result in search_response.get("items", []):
    if search_result["id"]["kind"] == "youtube#video":
      videos.append("%s" % (search_result["id"]["videoId"]))

  print videos[0]


if __name__ == "__main__":
  argparser.add_argument('channelId')
  argparser.add_argument('--q')
  args = argparser.parse_args()
  try:
    youtube_search(args)
  except HttpError, e:
    print "An HTTP error %d occurred:\n%s" % (e.resp.status, e.content)
