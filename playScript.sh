#! /bin/bash

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

function float_to_int() { 
	echo $1 | cut -d. -f1    # or use -d, if decimals separator is ,
}

function num_to_time() {
	num=$1
	hours=$(($num / 60 / 24))
	minutes=$(($num / 60 - $hours * 60))
	seconds=$(($num - $minutes * 60 - $hours * 60))
	
	if [ ${#hours} == 1 ]; then
		hours="0$hours"
	fi
	if [ ${#minutes} == 1 ]; then
		minutes="0$minutes"
	fi
	if [ ${#seconds} == 1 ]; then
		seconds="0$seconds"
	fi
	
	echo "$hours:$minutes:$seconds"
}

function draw_progress_bar() {
	total_cols=$1
	percents=$2
	total_draw=$(($percents * $total_cols / 100))
	for i in `seq 1 $total_draw`
	do
	   printf "="
	done
	printf ">"
	for i in `seq $total_draw $(($total_cols - 3))`
	do
		printf " "
	done
}

###############################		  Init MPlayer Control		###############################
#test_internet_connection
#internet_status=$?

#if [ $internet_status -eq 0 ]; then
#	echo "no internet connection. trying again in: $i"
#fi

#while [ $internet_status -eq 0 ]
#do
#	reset_terminal
#	for i in 3 2 1
#	do
#		echo "no internet connection. trying again in: $i"
#		sleep 1
#		reset_terminal
#	done
#	test_internet_connection
#	internet_status=$?
#done
reset_terminal


###############################			Main Loop			###############################

echo "link: $current_song_link, name: $current_song_name"

if [ $show_video_status -eq 0 ]; then
	options="-novideo -vo null"
else
	options="-vo gl"
fi

if [ "$current_song_name" != "" ]; then
	if [ -e "./saved_records/$current_song_name.mp4" ]; then
		echo "File exists"
		sudo stdbuf -oL mplayer $options -slave -input file=$path_to_remote_mplayer "./saved_records/$current_song_name.mp4" |
		{
			while IFS= read -r line; do
				if [[ "${line%=*}" == "ANS_length" ]]; then
					file_len="${line#*=}" #> ${line%=*}  # echo property_value > property_name
					#echo -e "\r$current_time / $file_len"
				elif [[ "${line%=*}" == "ANS_percent_pos" ]]; then
					percents="${line#*=}"
					#echo -e "\r$percents"
				elif [[ "${line%=*}" == "ANS_time_pos" ]]; then
					current_time="${line#*=}"
					cols_count=$(($(tput cols) - 25))
					#echo $cols_count $percents
					printf "\r$(num_to_time $(float_to_int $current_time)) $(draw_progress_bar $cols_count $percents)$(num_to_time $(float_to_int $file_len))"
				fi
			done
		}
	else
		echo "File './saved_records/$current_song_name.mp4' does not exist"
		test_internet_connection
		internet_status=$?
		if [ $internet_status -eq 0 ]; then
			echo "Can't download this file right now, there is no an internet connection."
		else
			. downloadScript.sh $current_song_link "$current_song_name" &
			youtube-dl --no-playlist "$current_song_link" -o - | mplayer $options -input file=$path_to_remote_mplayer -
		fi
	fi
fi

echo "0" > $path_to_status_update_file
