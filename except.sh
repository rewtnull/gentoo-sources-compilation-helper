# <piped expression>; except "exception message" # Returns first return code greater than 0 from pipe
except() {
    local pstatus=("${PIPESTATUS[@]}") i
    for (( i = 0; i < ${#pstatus[@]}; i++ )); do
	[[ ${pstatus[${i}]} -gt 0 ]] && { echo -e "\n${redfg}*${off} ${1} - Return Code: ${pstatus[${i}]}\n"; }
    done
}
