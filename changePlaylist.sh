#! /bin/bash

NAME="Youtube Player - Change Playlist"; echo -en "\033]0;$NAME\007"
echo -e "${GREEN}$NAME${NC}"

counter=0;
dictionary[0]="for declaration only";

echo -e "${YELLOW}Choose playlist (by number):"

OLD_IFS=$IFS
IFS=$'\n'
files_list=$(ls -f "$path_to_playlists_dir"/* 2>>./temp/err_log)
IFS=$OLD_IFS

# 0 => Cancel
echo -e "\t${GREEN}$counter\t\t${YELLOW}=>\t\t${WHITE}~~Cancel change~~"
counter=$(($counter+1));

# 1 => Default
echo -e "\t${GREEN}$counter\t\t${YELLOW}=>\t\t${WHITE}~~Default~~"
counter=$(($counter+1));

# 2 => Create new playlist
echo -e "\t${GREEN}$counter\t\t${YELLOW}=>\t\t${WHITE}~~Create new playlist~~"
counter=$(($counter+1));

for _file in $files_list
do
	echo -e "\t${GREEN}$counter\t\t${YELLOW}=>\t\t${WHITE}${_file:$((${#path_to_playlists_dir}+1)):$((${#_file[@]}-5))}";
	dictionary[$counter]="$_file";
	counter=$(($counter+1));
done
counter=$(($counter+1));
read selected

if [ $selected -eq 1 ]; then # Default
	echo "3$default_playlist" > $path_to_status_update_file
elif [ $selected -eq 2 ]; then # Create new
	echo -e "${YELLOW}Select new playlist's name:"
	read new_playlist_name
	echo "" > "$path_to_playlists_dir/$new_playlist_name"
elif [ $selected -gt 2 ]; then # Non-default playlist selected
	echo "3${dictionary[$selected]}" > $path_to_status_update_file
fi
