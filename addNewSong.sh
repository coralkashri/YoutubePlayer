#! /bin/bash

echo -e "Enter the link for the song:"
read new_song

if [ -z $(cat $playlist) ]; then
	echo -n "$new_song" > $playlist
else
	echo -n "$new_song" >> $playlist
fi

echo "Getting song's name..."
song_name=$(youtube-dl --no-playlist --get-title $new_song)

echo "+$song_name" >> $playlist

echo "1" > $path_to_status_update_file
