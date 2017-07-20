# largest(${array[@]} => $largest)
largest() {
    local array=("${@}")
    if (( ${#array[@]} > "1" )); then # If array consists of one single element it's already the largest one
	for (( i=0; i < ${#array[@]}; i++ )); do
	    gtoe "${array[${i}]}" "${largest_element}" && largest_element="${array[${i}]}"
	done
    else
	largest_element="${array[0]}"
    fi
    echo "${largest_element}"
}; unset largest_element
