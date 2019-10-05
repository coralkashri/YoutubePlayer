#! /bin/bash

#hash_table
counter=0
hash_table[0]=2
echo -e "${YELLOW}Choose playlist (by number):"
IFS=$'\n'
files_list=$(ls -f "$path_to_playlists_dir"/* 2>>./temp/err_log)

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
	hash_table[$counter]="$_file";
	counter=$(($counter+1));
done
counter=$(($counter+1));
read selected

if [ $selected -gt 2 ]; then
	echo "3${hash_table[$selected]}" > $path_to_status_update_file
elif [ $selected -eq 1 ]; then # Default
	echo "3$default_playlist" > $path_to_status_update_file
elif [ $selected -eq 2 ]; then # Create new
	echo -e "${YELLOW}Select new playlist's name:"
	read new_playlist_name
	echo "" > "$path_to_playlists_dir/$new_playlist_name.bin"
fi
