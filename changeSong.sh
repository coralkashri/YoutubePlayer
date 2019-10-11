#! /bin/bash

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
	song_name=${song_info[1]}
	echo -e "\t${GREEN}$counter\t\t${YELLOW}=>\t\t${WHITE}$song_name${NC}"
	counter=$(($counter+1));
done < $path_to_temp_playlist

read selected

if [ $selected -gt 0 -a $selected -lt $counter ]; then
	echo "4$selected" > $path_to_status_update_file
fi
