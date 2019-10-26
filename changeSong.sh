#! /bin/bash

NAME="Youtube Player - Change Song"; echo -en "\033]0;$NAME\007"
echo -e "${GREEN}$NAME${NC}"

selected=0
temp_songs_names_file="./temp/change_song_songs_names"
path_to_selection_res="./temp/change_song_selection"

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
done < "$path_to_temp_playlist"

./init/select_from_list.sh "Select song" $temp_songs_names_file $path_to_selection_res

#Get select
res=$(cat $path_to_selection_res)
OLD_IFS=$IFS
IFS='+'
read -a selected_info <<< "$res"
IFS=$OLD_IFS
selected=${selected_info[0]}

rm $temp_songs_names_file $path_to_selection_res

if [ $selected -gt 0 ]; then
	echo "4$selected" > $path_to_status_update_file
fi
