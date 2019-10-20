#! /bin/bash

NAME="Youtube Player - Change Song"; echo -en "\033]0;$NAME\007"
echo -e "${GREEN}$NAME${NC}"
echo -e "${YELLOW}Choose song:${NC}"

reset_terminal() {
	tput reset
	printf '\033[?7l' # Set Wrap OFF
	#printf '\033[?7h' # Set lines wrap ON
}

read_key() {
	_key() {
	  local kp
	  ESC=$'\e'
	  _KEY=
	  read -d '' -sn1 _KEY
	  case $_KEY in
		"$ESC")
		    while read -d '' -sn1 -t1 kp
		    do
		      _KEY=$_KEY$kp
		      case $kp in
		        [a-zA-NP-Z~]) break;;
		      esac
		    done
	    ;;
	  esac
	  printf -v "${1:-_KEY}" "%s" "$_KEY"
	}
	 
	_key x

	case $x in
	  $'\e[A' ) 	key=UP		;;
	  $'\e[B' ) 	key=DOWN	;;
	  $'\e[C' |\
	  $'\e[D' |\
	  ?) 			key=IGNORE	;;
	  *) 			key=EXIT 	;;
	esac

	eval $1=$key
}

selected=0
songs_count=$(wc -l < "$path_to_temp_playlist")

action="UP"
reset_terminal
while [ "$action" != "EXIT" ]; do
	if [ "$action" == "UP" ]; then # Decrease selected
		if [ $selected -gt 0 ]; then selected=$(($selected-1)); fi
	elif [ "$action" == "DOWN" ]; then  # Increase selected
		if [ $selected -lt $songs_count ]; then selected=$(($selected+1)); fi
	fi
	
	counter=0
	echo -e "${YELLOW}Choose song:${NC}"
	if [ $selected -eq $counter ]; then printf "\t${BG_BLUE}"; else printf "\t"; fi
	printf "${GREEN}$counter\t\t${YELLOW}=>\t\t${WHITE}~~Cancel change~~${NC}${BG_NONE}\n"
	counter=$(($counter+1));
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
		if [ $selected -eq $counter ]; then printf "\t${BG_BLUE}"; else printf "\t"; fi
		printf "${GREEN}$counter\t\t${YELLOW}=>\t\t${WHITE}$song_name${NC}${BG_NONE}\n"
		counter=$(($counter+1));
	done < $path_to_temp_playlist
	read_key action
	reset_terminal
done

if [ $selected -gt 0 ]; then
	echo "4$selected" > $path_to_status_update_file
fi
