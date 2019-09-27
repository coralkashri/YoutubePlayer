#!/bin/bash

###############################			Functions			###############################
function reset_terminal() {
	tput reset
}

# $1 => $arr
# The result array pass with echo, so to get the new array: n_array=$(round_array $array);
function round_array() {
	first=$1
	shift
	new_arr=$(echo ${@})
	new_arr[4]=$first
	echo ${new_arr[@]}
}

function test_internet_connection() {
	spinner_loader=("| \ - /");
	
	echo -e "${spinner_loader:0:1} \r";
	spinner_loader=$(round_array $spinner_loader);
	
	#internet_status=$(ping -q -w 1 -c 1 `ip r | grep default | cut -d ' ' -f 3` > /dev/null)
	$(wget -q --spider http://example.com);
	internet_status=$?

	for i in 1 2 3 4 5 6
	do
		reset_terminal
		echo -e "${spinner_loader:0:1} \r";
		spinner_loader=$(round_array $spinner_loader);
		sleep 0.1
	done
	
	if [ $internet_status -eq 0 ]
	then
		return 1;
	else
		return 0;
	fi
}

###############################		  Init MPlayer Control		###############################
test_internet_connection
internet_status=$?

#if [ $internet_status -eq 0 ]; then
#	echo "no internet connection. trying again in: $i"
#fi

while [ $internet_status -eq 0 ]
do
	reset_terminal
	for i in 3 2 1
	do
		echo "no internet connection. trying again in: $i"
		sleep 1
		reset_terminal
	done
	test_internet_connection
	internet_status=$?
done
reset_terminal


###############################			Main Loop			###############################

echo "link: $current_song_link, name: $current_song_name"

if [ -e "./saved_records/$current_song_name.mp4" ]; then
    echo "File exists"
	sudo mplayer -slave -input file=$path_to_remote_mplayer "./saved_records/$current_song_name.mp4"
else
    echo "File './saved_records/$current_song_name.mp4' does not exist"
	. downloadScript.sh $current_song_link "$current_song_name" &
	sudo mplayer -slave -input file=$path_to_remote_mplayer -cookies -cookies-file /tmp/cookie.txt -vo $(sudo youtube-dl -g --cookies /tmp/cookie.txt $current_song_link)
fi

echo "0" > $path_to_status_update_file
