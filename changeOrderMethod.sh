#!/bin/bash

function read_char() {
	read -n 1 char
	eval $1=$char
}

echo -e "${YELLOW}Choose order method:\n
${GREEN}0 => ${WHITE}Default\n
${GREEN}1 => ${WHITE}Loop\n
${GREEN}2 => ${WHITE}Oposite\n
${GREEN}3 => ${WHITE}Random\n
${GREEN}4 => ${WHITE}Cancel\n"


read_char method

case "$method" in
	"0" | "1" | "2" | "3")
		echo "2$method" > $path_to_status_update_file
	;;
esac
