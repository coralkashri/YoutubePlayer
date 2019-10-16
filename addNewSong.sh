#! /bin/bash

NAME="Youtube Player - Add New Song"; echo -en "\033]0;$NAME\007"
echo -e "${GREEN}$NAME${NC}"

echo -e "Enter the link for the song:"
read new_song

if [ -z $(cat $playlist) ]; then
	echo -n "$new_song" > $playlist
else
	echo -n "$new_song" >> $playlist
fi

echo "Getting song's name..."
song_name=$(youtube-dl --no-playlist --get-title $new_song)

echo "Enter song name (blank for: '$song_name'):"

read new_song_name
echo "+$song_name+$new_song_name" >> $playlist

#echo "+$song_name" >> $playlist

echo "1" > $path_to_status_update_file
