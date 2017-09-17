# Greater than or equal for string comparisons

gtoe() {
    local first="${1}"
    local second="${2}"
    local re="^[0-9]{1,2}\.[0-9]{1,2}\.[0-9]$"

    [[ ${first} =~ ${re} ]] && first=$(echo ${first} | perl -pe 's/(.$)/0\1/')
    [[ ${second} =~ ${re} ]] && second=$(echo ${second} | perl -pe 's/(.$)/0\1/')

    [[ "${first}" > "${second}" || "${first}" == "${second}" ]]
}
