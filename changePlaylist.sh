#! /bin/bash

NAME="Youtube Player - Change Playlist"; echo -en "\033]0;$NAME\007"
echo -e "${GREEN}$NAME${NC}"

selected=0
temp_playlists_names_file="./temp/change_playlist_playlists_names"
path_to_selection_res="./temp/change_playlist_selection"
#dictionary[0]="for declaration only";

printf "" > $temp_playlists_names_file

OLD_IFS=$IFS
IFS=$'\n'
files_list=$(ls -f "$path_to_playlists_dir"/* 2>>./temp/err_log)
IFS=$OLD_IFS

echo "~~Default~~" >> $temp_playlists_names_file # 1 => Default
echo "~~Create new playlist~~" >> $temp_playlists_names_file # 2 => Create new playlist
for _file in $files_list; do
	echo "${_file:$((${#path_to_playlists_dir}+1))}" >> $temp_playlists_names_file
done

./init/select_from_list.sh "Choose playlist" $temp_playlists_names_file $path_to_selection_res

res=$(cat $path_to_selection_res)
OLD_IFS=$IFS
IFS='+'
read -a selected_info <<< "$res"
IFS=$OLD_IFS

rm $temp_playlists_names_file $path_to_selection_res

if [ ${selected_info[0]} -eq 1 ]; then # Default
	echo "3$default_playlist" > $path_to_status_update_file
elif [ ${selected_info[0]} -eq 2 ]; then # Create new
	echo -e "${YELLOW}Select new playlist's name:"
	read new_playlist_name
	echo "" > "$path_to_playlists_dir/$new_playlist_name"
elif [ ${selected_info[0]} -gt 2 ]; then # Non-default playlist selected
	echo "3$path_to_playlists_dir/${selected_info[1]}" > $path_to_status_update_file
fi
