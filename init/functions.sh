#! /bin/bash

###############################		    Functions			###############################
# $1 => $arr
# The result array pass with echo, so to get the new array: n_array=$(round_array $array);
function round_array() {
	first=$1
	shift
	new_arr=$(echo ${@})
	new_arr[4]=$first
	echo ${new_arr[@]}
}

function reset_terminal() {
	tput reset
}

# read_char [address]var
function read_char() {
	read -n 1 char
	eval $1=$char
}

# $1 => [address]var
function read_char_if_availible() {
	read -n 1 -t 1 char
	eval $1=$char
}

# is_command_exist "command name" [address]res_var
function is_command_exist() {
	local command_name
	local exist
	command_name="$1"
	exist=$(type $command_name)
	if [ ${exist:0:${#command_name}} == $command_name ]
	then
		eval $2=1
	else
		eval $2=0
	fi
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
	
	if [ "$internet_status" == "0" ]
	then
		echo "1"
	else
		echo "0"
	fi
}

function next_song_index() {
	if [ $songs_count -gt 0 ]; then
		current_index=$((($current_index)%$songs_count + 1))
		if [ $current_index -eq 1 ] && [ "$order_method" == "3" ]; then
			update_tmp_playlist
		fi
	fi
}

function prev_song_index() {
	current_index=$(($current_index-1))
	if [ $current_index -lt 1 ]
	then
		current_index=$songs_count
	fi
	#gnome-terminal -e "echo $current_index" --window-with-profile="hold-open"
}

function next_song_by_order_method() {
	case "$order_method" in
	"1") # Loop		
		;;

	*) # No Loop
		next_song_index
		;;
	esac
}

function update_tmp_playlist() {
	if [ "$order_method" != "1" ]; then
		echo "" > $path_to_temp_playlist;
	fi

	case "$order_method" in
	"0") # Default
		cat $playlist > $path_to_temp_playlist
	;;
	"1") # Loop
		if [ $(grep -vxFf $playlist $path_to_temp_playlist | wc -l) -gt 0 -o $(grep -vxFf $path_to_temp_playlist $playlist | wc -l) -gt 0 ]; then 
			# Difference detected
			# Method:
			# 1. Get the current song's name: 			$current_song_name
			# 2. Update current playlist: 				cat $playlist > $path_to_temp_playlist
			# 3. Find current song in the new list:		new_song_idx=$(cat $playlist | grep -n "$current_song_name" | awk -F: '{print $1}')
			# 4. Apply the new song's index:			current_index=$new_song_idx
			cat $playlist > $path_to_temp_playlist
			new_song_idx=$(cat $playlist | grep -n "$current_song_name" | awk -F: '{print $1}')
			current_index=$new_song_idx
		fi
	;;
	"2") # Oposite
		tac $playlist > $path_to_temp_playlist;
	;;
	"3") # Random
#		current_index=$(($RANDOM % $songs_count + 1 | bc))
		cat $playlist | shuf > $path_to_temp_playlist;
	;;
	esac
}

function update_songs_count() {
	songs_count=$(wc -l < "$playlist")
}

function print_current_playlist() {
	echo -e "${GREEN}Current Playlist ($playlist):${WHITE}"
	temp_songs_names="./temp/songs_names";
	temp_songs_names1="./temp/songs_names1";
	echo -n "" > $temp_songs_names
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
		echo "$song_name" >> $temp_songs_names;
	done < $path_to_temp_playlist
	cat $temp_songs_names > $temp_songs_names1
	awk -v cs="$current_song_display_name" 'BEGIN{FS="\n"} {if($1 == cs) {printf "\033[0;31m";} else {printf "\033[1;37m";} printf $1 "\033[1;37m\n"}' $temp_songs_names1 > $temp_songs_names
#	awk -v cs=$current_song_name 'BEGIN{FS="\n"} {printf $1 "\n" cs "\n"}' $temp_songs_names1 > $temp_songs_names 
	pr -TW120 -2 $temp_songs_names
	sudo rm $temp_songs_names $temp_songs_names1
	echo -e "${NC}\n\n"
	#echo -e $(pr -tw100 -2 $temp_songs_names)
}

# $1 => $show_playlist_status
# $2 => $show_video_status
function print_options() {
	echo -e "${RED}Choose option:
${GREEN}0. ${WHITE}$(get_show_hide_oposite_status $1) playlist
${GREEN}1. ${WHITE}Play
${GREEN}2. ${WHITE}Pause / continue
${GREEN}3. ${WHITE}Prev song
${GREEN}4. ${WHITE}Next song
${GREEN}5. ${WHITE}Add song
${GREEN}6. ${WHITE}Remove song
${GREEN}7. ${WHITE}Change song
${GREEN}8. ${WHITE}Change order method
${GREEN}+. ${WHITE}Increase volume
${GREEN}-. ${WHITE}Decrease volume
${GREEN}f. ${WHITE}Full screen
${GREEN}v. ${WHITE}$(get_show_hide_oposite_status $2) video
${GREEN}c. ${WHITE}Change playlist
${GREEN}u. ${WHITE}Update playlist songs names
${GREEN}9. ${WHITE}Exit${NC}\n\n"
}

# $1 => 0  -> Show (Currently hidden)
# $1 => !0 -> Hide (Currently shown)
function get_show_hide_oposite_status() {
	ret_val=""
	if [ $1 -eq 0 ]; then
		ret_val="${GREEN}Show${WHITE}"
	else
		ret_val="${GREEN}Hide${WHITE}"
	fi
	echo $ret_val
}

function comming_soon_msg() {
	reset_terminal
	echo -e ${YELLOW}Comming soon, press any key to continue.${WHITE}
	read_char
}
