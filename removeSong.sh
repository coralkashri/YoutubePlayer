#! /bin/bash

NAME="Youtube Player - Remove Song"; echo -en "\033]0;$NAME\007"
echo -e "${GREEN}$NAME${NC}"
echo -e "${YELLOW}Choose song (by number):${NC}"

counter=0

# 0 => Cancel
echo -e "\t${GREEN}$counter\t\t${YELLOW}=>\t\t${WHITE}~~Cancel change~~"
counter=$(($counter+1));

while read current_song;
do
	OLD_IFS=$IFS
	IFS='+'
	read -a song_info <<< "$current_song"
	IFS=$OLD_IFS
	if [ "${song_info[2]}" == "" ]; then
		song_name="${song_info[1]}"
	else
		song_name="${song_info[2]}"
	fi
	echo -e "\t${GREEN}$counter\t\t${YELLOW}=>\t\t${WHITE}$song_name${NC}"
	counter=$(($counter+1));
done < $playlist

read selected
path_to_temp_new_playlist="./temp/remove_song_temp_new_playlist"
selected_song_info=$(sed "${selected}q;d" $playlist)

grep -v "$selected_song_info" $playlist > $path_to_temp_new_playlist && mv $path_to_temp_new_playlist $playlist

if [ $selected -gt 0 -a $selected -lt $counter ]; then
	echo "5" > $path_to_status_update_file
fi
