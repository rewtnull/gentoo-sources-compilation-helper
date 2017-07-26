yestoall(){
    echo ""
    if [[ ${yestoall} == "1" ]]; then
	REPLY="y"
    else
	read -rp "${1} "
    fi
}
