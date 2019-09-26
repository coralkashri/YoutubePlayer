#! /bin/bash


current_song_link=$1
song_name=$2

youtube-dl --no-playlist -f mp4 --output "./saved_records/$song_name.mp4" "$current_song_link"
