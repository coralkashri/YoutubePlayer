#! /bin/bash

if [ "$1" != "" ]
then
	update_dependencies=1
fi

tput reset
SCRIPT=$(readlink -f $0)
SCRIPTPATH=`dirname $SCRIPT`
cd $SCRIPTPATH
NAME="Youtube Player"; echo -en "\033]0;$NAME\007"
sudo echo ""

###############################		 Global Vriables		###############################
declare -a current_index
declare -a songs_count

###############################   		Functions			###############################
set -a 
source ./init/functions.sh
set +a

############################### 		Variables 			###############################

######## Colors Define ########
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[1;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'

export RED NC GREEN BLUE YELLOW WHITE PURPLE

###### Variables Define #######

default_playlist="./playlist"
export default_playlist

playlist=$default_playlist
export playlist

songs_count=$(wc -l < "$playlist")

current_index=0 # starts with 1
export current_index

current_song_link=""
export current_song_link
current_song_name=""
export current_song_name
current_song_display_name=""
export current_song_display_name

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

path_to_temp_playlist="./temp/tmp_playlist";
export path_to_temp_playlist

path_to_playlists_dir="./playlists"
export path_to_playlists_dir

show_playlist_status=0 # hide/show current playlist
show_video_status=1 # hide/show video
export show_video_status

###############################		Check for youtube-dl	###############################

is_command_exist "youtube-dl" exist_test
if [ "$exist_test" == "1" ]
then
	if [ "$update_dependencies" == "" ]; then
		sudo youtube-dl -U
	fi
	echo "youtube-dl is ready for use."
else
	echo "youtube-dl is not exist, do you want to install it now?"
	read_char ans
	if [ "$ans" == "y" ]
	then
		sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
		sudo chmod 777 /usr/local/bin/youtube-dl
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
function update_mplayer() {
	sudo cat /etc/apt/sources.list | grep "deb http://ppa.launchpad.net/rvm/mplayer/ubuntu karmic main" > null
	if [ "$?" == "1" ]; then
		sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
		sudo echo "deb http://ppa.launchpad.net/rvm/mplayer/ubuntu karmic main" >> /etc/apt/sources.list
		sudo add-apt-repository ppa:jonathonf/ffmpeg-3 -y
	fi
	sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 03E02400
	sudo apt-get update
	sudo apt-get install mplayer
	sudo apt install ffmpeg -y
}

is_command_exist "mplayer" exist_test
if [ "$exist_test" == "1" ]
then
	if [ "$update_dependencies" == "" ]; then
		update_mplayer
	fi
	echo "mplayer is ready for use."
else
	echo "mplayer is not exist, do you want to install it now?"
	read_char ans
	if [ "$ans" == "y" ]
	then
		sudo apt-get install mplayer mplayer-gui mplayer-skins
		update_mplayer
		clear
		echo "mplayer is ready for use now."
	else
		exit
	fi
fi

sleep 1
reset_terminal


###############################	   Check Internet Connection	###############################
#internet_status=$(test_internet_connection)
#while [ "$internet_status" == "0" ]
#do
#	reset_terminal
#	for i in 3 2 1
#	do
#		echo "no internet connection. trying again in: $i"
#		sleep 1
#		reset_terminal
#	done
#	internet_status=$(test_internet_connection)
#done
#reset_terminal


###############################		  Init Perrmissions		###############################
sudo echo "" > $path_to_status_update_file
sudo mkdir ./saved_records
rm -R ./temp
sudo mkdir ./temp
sudo mkdir $path_to_playlists_dir
sudo echo "" > $path_to_temp_playlist;
sudo chmod a+rwx ./*;
update_tmp_playlist
reset_terminal


###############################		  Init MPlayer Control		###############################
sudo rm $path_to_remote_mplayer
mkfifo $path_to_remote_mplayer
sudo apt install wmctrl
reset_terminal


###############################			Main Loop			###############################
while true
do
	print_options $show_playlist_status $show_video_status
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
		elif [ "${status:0:1}" == "4" ]; then # Change song
			current_index="${status:1}"
			echo "quit" > $path_to_remote_mplayer
			user_interrupted_order=1
		elif [ "${status:0:1}" == "5" ]; then # Remove song
			songs_count=$(($songs_count-1))
			update_tmp_playlist
		fi
		sudo echo "" > $path_to_status_update_file
	fi

	if [ $songs_count -eq 0 ]; then
		next_ready=0
	fi

	if [ $next_ready -eq 1 ]
	then
		method="1"
		next_ready=0
	fi

	case "$method" in
	"0") #Show/Hide playlist
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
			current_song_name="${data[1]}"
			if [ "${data[2]}" == "" ]; then
				current_song_display_name="${data[1]}"
			else
				current_song_display_name="${data[2]}"
			fi
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
		gnome-terminal -e ./removeSong.sh
		;;

	"7") # Change Song
		gnome-terminal -e ./changeSong.sh
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

	"v") # Show/Hide video
		if [ "$show_video_status" == "0" ]; then
			show_video_status=1
		else
			show_video_status=0
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

unset current_index songs_count \
		default_playlist playlist songs_count current_index current_song_link current_song_name wait_for_start method is_playing next_ready is_fullscreen \
		order_method user_interrupted_order path_to_remote_mplayer path_to_status_update_file path_to_temp_playlist path_to_playlists_dir show_playlist_status
		
exit
