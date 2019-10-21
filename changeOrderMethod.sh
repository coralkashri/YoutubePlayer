#!/bin/bash

temp_order_options_file="./temp/change_rder_method_options"
path_to_selection_res="./temp/change_order_method_selection"

printf "" > $temp_order_options_file
echo "Default" >> $temp_order_options_file
echo "Loop" >> $temp_order_options_file
echo "Oposite" >> $temp_order_options_file
echo "Random" >> $temp_order_options_file


./init/select_from_list.sh "Choose order method" $temp_order_options_file $path_to_selection_res

res=$(cat $path_to_selection_res)
OLD_IFS=$IFS
IFS='+'
read -a selected_info <<< "$res"
IFS=$OLD_IFS
selected=$((${selected_info[0]} - 1)) # -1 => Ignore the 'Cancel' option

case "$selected" in
	"0" | "1" | "2" | "3")
		echo "2$selected" > $path_to_status_update_file
	;;
esac
