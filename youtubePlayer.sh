#!/bin/bash

if [ "$1" != "" ]
then
	update_dependencies=1
fi

tput reset
SCRIPT=$(readlink -f $0)
SCRIPTPATH=`dirname $SCRIPT`
cd $SCRIPTPATH
NAME="Youtube Streaming"; echo -en "\033]0;$NAME\a"
sudo ls -l;

###############################		 Global Vriables		###############################
declare -a current_index
declare -a songs_count


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
	#tput reset
	echo "";
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
	current_index=$((($current_index)%$songs_count + 1))
	if [ $current_index -eq 1 ] && [ "$order_method" == "3" ]; then
		update_tmp_playlist
	fi
	#gnome-terminal -e "echo $current_index" --window-with-profile="hold-open"
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

	*)
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
		cat $playlist > $path_to_temp_playlist;
	;;
	"1") # Loop
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
	echo -e "${GREEN}Current Playlist:${WHITE}"
	temp_songs_names="./temp/songs_names.bin";
	temp_songs_names1="./temp/songs_names1.bin";
	echo -n "" > $temp_songs_names
	while read current_song;
	do
		OLD_IFS=$IFS
		IFS='+'
		read -a song_info <<< "$current_song"
		IFS=$OLD_IFS
		song_name=${song_info[1]}
		echo $song_name >> $temp_songs_names;
	done < $path_to_temp_playlist
	echo $(sudo cat $temp_songs_names) > $temp_songs_names1
	awk -v cs=$current_song_name 'BEGIN{FS="\n"} {if($1 == cs) {printf "\033[0;31m";} else {printf "\033[1;37m";} printf $1 "\033[1;37m\n"}' $temp_songs_names1 > $temp_songs_names
#	echo $current_song_name
#	awk -v cs=$current_song_name 'BEGIN{FS="\n"} {printf $1 "\n" cs "\n"}' $temp_songs_names1 > $temp_songs_names
	pr -tw100 -2 $temp_songs_names
	echo -e "\n\n"
	#echo -e $(pr -tw100 -2 $temp_songs_names)
}

function print_options() {
	echo -e "${RED}Choose option:
${GREEN}0. ${WHITE}$(get_show_hide_playlist_oposite_status) playlist
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
${GREEN}c. ${WHITE}Change playlist
${GREEN}u. ${WHITE}Update playlist songs names
${GREEN}9. ${WHITE}Exit\n\n"
}

function get_show_hide_playlist_oposite_status() {
	ret_val=""
	if [ $show_playlist_status -eq 0 ]; then
		ret_val="Show"
	else
		ret_val="Hide"
	fi
	echo "$ret_val" >> ${HOME}/Desktop/test
	echo $ret_val

}

############################### 		Variables 			###############################

######## Colors Define ########
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'

export RED NC GREEN BLUE YELLOW WHITE PURPLE

###### End Colors Define ######

default_playlist="./playlist.bin"
export default_playlist

playlist=$default_playlist
export playlist

songs_count=$(wc -l < "$playlist")

current_index=0 # starts with 1

current_song_link=""
export current_song_link
current_song_name=""
export current_song_name

wait_for_start=false

method=0

is_playing=0
export is_playing

next_ready=0
export next_ready

is_fullscreen=0

order_method=0 # 0-> default; 1-> loop; 2-> reversing; 3-> random;
user_interrupted_order=0

#path_to_remote_mplayer="$HOME/Desktop/mplayer-control";
path_to_remote_mplayer="./temp/mplayer-control";
export path_to_remote_mplayer

path_to_status_update_file="./updateStatus";
export path_to_status_update_file

path_to_temp_playlist="./temp/tmp_playlist.bin";

path_to_playlists_dir="./playlists"
export path_to_playlists_dir

#optionsPrint="echo -e ${RED}Choose option:\n
#${GREEN}0. ${WHITE}$(get_show_hide_playlist_oposite_status) playlist\n
#${GREEN}1. ${WHITE}Play\n
#${GREEN}2. ${WHITE}Pause / continue\n
#${GREEN}3. ${WHITE}Prev song\n
#${GREEN}4. ${WHITE}Next song\n
#${GREEN}5. ${WHITE}Add song\n
#${GREEN}6. ${WHITE}Remove song\n
#${GREEN}7. ${WHITE}Change song\n
#${GREEN}8. ${WHITE}Change order method\n
#${GREEN}+. ${WHITE}Increase volume\n
#${GREEN}-. ${WHITE}Decrease volume\n
#${GREEN}f. ${WHITE}Full screen\n
#${GREEN}c. ${WHITE}Change playlist\n
#${GREEN}u. ${WHITE}Update playlist songs names\n
#${GREEN}9. ${WHITE}Exit\n\n"

show_playlist_status=0 # hide/show current playlist


###############################		Check for youtube-dl	###############################

is_command_exist "youtube-dl" exist_test
if [ "$exist_test" -eq "1" ]
then
	if [ "$update_dependencies" == "" ]; then
		sudo apt-get upgrade youtube-dl -y
		sudo youtube-dl -U
	fi
	echo "youtube-dl is ready for use."
else
	echo "youtube-dl is not exist, do you want to install it now?"
	read_char ans
	if [ "$ans" == "y" ]
	then
		sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
		sudo chmod a+rx /usr/local/bin/youtube-dl
		sudo youtube-dl -U
		clear
		echo "youtube-dl is ready for use now."
	else
		exit
	fi
fi

sleep 1
reset_terminal


###############################		  Check for mplayer		###############################
is_command_exist "mplayer" is_command_exist "youtube-dl"
if [ "$exist_test" -eq "1" ]
then
	if [ "$update_dependencies" == "" ]; then
		sudo apt-get upgrade mplayer -y
	fi
	echo "mplayer is ready for use."
else
	echo "mplayer is not exist, do you want to install it now?"
	read_char ans
	if [ "$ans" == "y" ]
	then
		sudo apt-get install mplayer mplayer-gui mplayer-skins
		clear
		echo "mplayer is ready for use now."
	else
		exit
	fi
fi

sleep 1
reset_terminal

###############################		  Init MPlayer Control		###############################
sudo rm $path_to_remote_mplayer
mkfifo $path_to_remote_mplayer
sudo apt install wmctrl
reset_terminal


###############################	   Check Internet Connection	###############################
internet_status=$(test_internet_connection)
while [ "$internet_status" == "0" ]
do
	reset_terminal
	for i in 3 2 1
	do
		echo "no internet connection. trying again in: $i"
		sleep 1
		reset_terminal
	done
	internet_status=$(test_internet_connection)
done
reset_terminal


###############################		  Init Perrmissions		###############################
sudo echo "" > $path_to_status_update_file
sudo mkdir ./saved_records
rm ./temp
sudo mkdir ./temp
sudo mkdir $path_to_playlists_dir
sudo echo "" > $path_to_temp_playlist;
sudo chmod a+rwx ./*;
update_tmp_playlist
reset_terminal


###############################			Main Loop			###############################
while true
do
	print_options
	if [ "$show_playlist_status" == "1" ]; then
		print_current_playlist
	fi

	read_char_if_availible method

	status=$(sed "1q;d" $path_to_status_update_file)
	if [[ ! -z "$status" ]] ; then
		if [ "$status" == "0" ]; then # End song, ready for the next one
			is_playing=0;
			next_ready=1;
		elif [ "$status" == "1" ]; then # Increase songs count
			songs_count=$(($songs_count+1))
			if [ "${current_index}" == "1" ]; then
				current_index=$songs_count;
			fi
			update_tmp_playlist
		elif [ "${status:0:1}" == "2" ]; then # Change order method
			order_method=${status:1:2}
			echo "$order_method"
			update_tmp_playlist
		elif [ "${status:0:1}" == "3" ]; then # Change playlist
			playlist="${status:1}"
			update_songs_count
			update_tmp_playlist
		fi
		sudo echo "" > $path_to_status_update_file
	fi

	if [ $next_ready -eq 1 ]
	then
		method="1"
		next_ready=0
	fi

	case "$method" in
	"0")
		if [ "$show_playlist_status" == "0" ]; then
			show_playlist_status=1
		else
			show_playlist_status=0
		fi
		;;

	"1") #Play
		if [ "$is_playing" == "0" ] && [ $songs_count -gt 0 ]
		then
			if [ $user_interrupted_order -eq 0 ]
			then
				next_song_by_order_method
			else
				user_interrupted_order=0
			fi			
			echo -ne '                              (0%)\r';
			sleep 0.05;
			wait_for_start=false;
			echo -ne '###                           (10%)\r';
			sleep 0.05;
			current_song_info=$(sed "${current_index}q;d" $path_to_temp_playlist); # Format: "$song_link+$song_name"
			OLD_IFS=$IFS
			IFS='+'
			read -a data <<< "$current_song_info"
			IFS=$OLD_IFS
			current_song_link=${data[0]}
			current_song_name=${data[1]}
			echo -ne '######                        (20%)\r'
			sleep 0.05
			echo -ne '########                      (25%)\r'
			sleep 0.05
			echo -ne '############                  (40%)\r'
			sleep 0.05
			is_playing=1
			echo -ne '###############               (50%)\r'
			#play_method="mplayer -slave -input file=$path_to_remote_mplayer -cookies -cookies-file /tmp/cookie.txt -vo $(youtube-dl -g --cookies /tmp/cookie.txt $current_song_link);is_playing=0;"
			#gnome-terminal -e "echo $play_method" --window-with-profile="hold-open"
			. playScript.sh &
			echo -ne '###########################   (95%)\r'
			sleep 1s
			#wmctrl -a "Youtube Streaming"
			if [ $is_fullscreen -eq 1 ]
			then
				echo "vo_fullscreen 1" > $path_to_remote_mplayer
			fi
			echo -ne '##############################(100%)\r'
			sleep 0.5
		fi
		;;

	"2") # Pause
		if [ $is_playing -eq 1 ]
		then
			echo "pause" > $path_to_remote_mplayer
		fi
		;;

	"3") # Prev song
		if [ $is_playing -eq 1 ]
		then
			echo "quit" > $path_to_remote_mplayer
		fi
		prev_song_index
		user_interrupted_order=1
		;;

	"4") # Next song
		if [ $is_playing -eq 1 ]
		then
			echo "quit" > $path_to_remote_mplayer
		fi
		next_song_index
		user_interrupted_order=1
		;;

	"5") # Add Song
		gnome-terminal -e ./addNewSong.sh
		;;

	"6") # Remove Song
		;;

	"7") # Change Song
		;;

	"8") # Change order method
		gnome-terminal -e ./changeOrderMethod.sh
		;;

	"+") # Increase volume
		if [ $is_playing -eq 1 ]
		then
			echo "volume +1" > $path_to_remote_mplayer
		fi
		;;

	"-") # Decrease volume
		if [ $is_playing -eq 1 ]
		then
			echo "volume -1" > $path_to_remote_mplayer
		fi
		;;

	"f") # Fullscreen
		if [ $is_playing -eq 1 ]
		then
			let is_fullscreen=$is_fullscreen?0:1
			echo "vo_fullscreen $is_fullscreen" > $path_to_remote_mplayer
		fi
		;;

	"c") # Change playlist
		gnome-terminal -e ./changePlaylist.sh
		;;

	"u") # Update songs names
		gnome-terminal -e ./changePlaylist.sh
		;;

	"9") # Exit
		if [ $is_playing -eq 1 ]
		then
			echo "quit" > $path_to_remote_mplayer
		fi
		break
		;;

	*)
		;;
	esac
	reset_terminal

done
unset is_playing
unset next_ready

exit
