#! /bin/bash

#######################################
#
# Playlist format:
#
# Separate char: '+'
#
# Data order:
### 1. Song link
### 2. Song's source name
### 3. Song's user selected name 	(Optional)
### 4. Start playing time in sec 	(Optional)
### 5. Stop playing time in sec 	(Optional)
#
# Examples:
### www.youtube.com/blabl$#a+song name+my song name+10+50 -> link: www.youtube.com/blabl$#a | source name: song name | displayed name: my song name | start time: 10 | stop time: 50
### www.youtube.com/blabl$#a+song name++10+ -> link: www.youtube.com/blabl$#a | source name: song name | displayed name: song name | start time: 10 | stop time: -
### www.youtube.com/blabl$#a+song name+++50 -> link: www.youtube.com/blabl$#a | source name: song name | displayed name: song name | start time: 0 | stop time: 50
### www.youtube.com/blabl$#a+song name++10+60 -> link: www.youtube.com/blabl$#a | source name: song name | displayed name: song name | start time: 10 | stop time: 60
### www.youtube.com/blabl$#a+song name+my song name+53+ -> link: www.youtube.com/blabl$#a | source name: song name | displayed name: my song name | start time: 53 | stop time: -
### www.youtube.com/blabl$#a+song name+my song name++56 -> link: www.youtube.com/blabl$#a | source name: song name | displayed name: my song name | start time: 0 | stop time: 56
#
#
#######################################

NAME="Youtube Player - Add New Song"; echo -en "\033]0;$NAME\007"
echo -e "${GREEN}$NAME${NC}"

echo -e "Enter the link for the song:"
read new_song

if [ -z "$(cat $playlist)" ]; then
	echo -n "$new_song" > $playlist
else
	echo -n "$new_song" >> $playlist
fi

echo "Getting song's name..."
song_name=$(youtube-dl --no-playlist --get-title $new_song)

echo "Enter song name (blank for: '$song_name'):"

read new_song_name
echo "+$song_name+$new_song_name++" >> $playlist

#echo "+$song_name" >> $playlist

echo "1" > $path_to_status_update_file
