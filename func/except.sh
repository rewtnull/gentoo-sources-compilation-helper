# <piped expression>; except "exception message" # Returns first return code greater than 0 from pipe
except() {
    local pstatus=("${PIPESTATUS[@]}")
    for (( i = 0; i < ${#pstatus[@]}; i++ )); do
	[[ ${pstatus[${i}]} -gt 0 ]] && { echo -e "\n\e[91m*\e[0m ${1} - Return Code: ${pstatus[${i}]}\n"; exit; }
    done
}
