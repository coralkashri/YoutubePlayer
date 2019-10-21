#! /bin/bash

NAME="Youtube Player - Remove Song"; echo -en "\033]0;$NAME\007"
echo -e "${GREEN}$NAME${NC}"

temp_songs_names_file="./temp/remove_song_songs_names"
path_to_selection_res="./temp/remove_song_selection"

printf "" > $temp_songs_names_file
#songs_list=()
while read current_song; do
	OLD_IFS=$IFS
	IFS='+'
	read -a song_info <<< "$current_song"
	IFS=$OLD_IFS
	if [ "${song_info[2]}" == "" ]; then
		song_name="${song_info[1]}"
	else
		song_name="${song_info[2]}"
	fi
	echo "$song_name" >> $temp_songs_names_file
done < $playlist

./init/select_from_list.sh "Remove song" $temp_songs_names_file $path_to_selection_res

#Get select
res=$(cat $path_to_selection_res)
OLD_IFS=$IFS
IFS='+'
read -a selected_info <<< "$res"
IFS=$OLD_IFS
selected=${selected_info[0]}

path_to_temp_new_playlist="./temp/remove_song_temp_new_playlist"
selected_song_info=$(sed "${selected}q;d" $playlist)

grep -v "$selected_song_info" $playlist > $path_to_temp_new_playlist && mv $path_to_temp_new_playlist $playlist

if [ $selected -gt 0 ]; then
	echo "5" > $path_to_status_update_file
fi
