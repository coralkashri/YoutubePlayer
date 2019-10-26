#! /bin/bash

NAME="Youtube Player - Modify Song"; echo -en "\033]0;$NAME\007"
echo -e "${GREEN}$NAME${NC}"

selected=0
temp_songs_names_file="./temp/modify_song_songs_names"
path_to_selection_res="./temp/modify_song_selection"

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
done < "$playlist"

./init/select_from_list.sh "Modify song" $temp_songs_names_file $path_to_selection_res

#Get select
res=$(cat $path_to_selection_res)
OLD_IFS=$IFS
IFS='+'
read -a selected_info <<< "$res"
IFS=$OLD_IFS
selected=${selected_info[0]}

rm $temp_songs_names_file $path_to_selection_res

if [ $selected -gt 0 ]; then
	
	## Get new properties
	echo "Enter new song name [leave blank for '${selected_info[1]}']:"
	read new_song_name
	if [ "$new_song_name" == "" ]; then
		new_song_name=${selected_info[1]}
	fi
	
	selected_song_full_info=$(sed "${selected}q;d" "$playlist"); # Format: "$song_link+$song_name"
	OLD_IFS=$IFS
	IFS='+'
	read -a data <<< "$selected_song_full_info"
	IFS=$OLD_IFS
	
	if [ "${data[3]}" == "" ]; then
		current_start=0
	else
		current_start=${data[3]}
	fi
	if [ "${data[4]}" == "" ]; then
		current_end="None"
	else
		current_end=${data[4]}
	fi
	
	echo "Enter new start point in seconds [blank for $current_start | number]:"
	read new_start
	if [ "$new_start" == "" ]; then
		new_start=${data[3]}
	fi
	
	echo "Enter new end point in seconds [blank for $current_end | 'none' for no end | number]:"
	read new_end
	if [ "$new_end" == "" ]; then
		new_end=${data[4]}
	elif [ "$new_end" == "none" ]; then
		new_end=""
	fi
	
	## Updating
	function escape_slashes {
		sed 's/\//\\\//g' 
	}

	function change_line {
		local OLD_LINE_PATTERN=$1; shift
		local NEW_LINE=$1; shift
		local FILE=$1

		local OLD=$(echo "${OLD_LINE_PATTERN}" | escape_slashes)
		local NEW=$(echo "${NEW_LINE}" | escape_slashes)
		sed -i "/$OLD/c$NEW" "$FILE"
	}
	new_line="${data[0]}+${data[1]}+$new_song_name+$new_start+$new_end"
	
	change_line "$selected_song_full_info" "$new_line" "$playlist"
	
	echo "6" > $path_to_status_update_file
fi
