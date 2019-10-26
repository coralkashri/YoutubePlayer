#! /bin/bash

# This scripts receives a title (first arg), path to items list file, and a path to the res file. With a nice gui the user can pick one item, or cancel the choose.
# The result is the selected item details:
# "item_id+item_data"
# For cancel, the function returns: "0+Cancel"
# Call example:
# select_from_list.sh title path/to/file_list path/to/res_file

list_title=$1
path_to_list=$2
path_to_res=$3
echo '~~Cancel~~' | cat - "$path_to_list" > ./temp/select_from_list_temp && mv ./temp/select_from_list_temp "$path_to_list"

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
items_count=$(wc -l < "$path_to_list")
available_terminal_lines=$(($(tput lines) - 2)) # -2 -> title + end line

action="IGNORE"
reset_terminal
while [ "$action" != "EXIT" ]; do
	if [ "$action" == "UP" ]; then # Decrease selected
		if [ $selected -gt 0 ]; then selected=$(($selected-1)); fi
	elif [ "$action" == "DOWN" ]; then  # Increase selected
		if [ $selected -lt $(($items_count - 1)) ]; then selected=$(($selected+1)); fi
	fi
	
	list_start=$selected
	if [ $(($list_start + $available_terminal_lines)) -gt $items_count ]; then
		list_start=$(($items_count - $available_terminal_lines))
	fi
	counter=0
	echo -e "${YELLOW}${list_title}:${NC}"
	while read current_item; do
		if [ $counter -lt $list_start ]; then
			counter=$(($counter + 1));
			continue;
		fi 
		if [ $selected -eq $counter ]; then printf "\t${BG_BLUE}"; else printf "\t"; fi
		printf "${GREEN}$counter\t\t${YELLOW}=>\t\t${WHITE}$current_item${NC}${BG_NONE}\n"
		counter=$(($counter+1));
		if [ $counter -ge $(($available_terminal_lines + $list_start)) ]; then break; fi
	done < $path_to_list
	read_key action
	reset_terminal
done

res_data=$(sed "$(($selected + 1))q;d" $path_to_list)
printf "$selected+$res_data" > $path_to_res
