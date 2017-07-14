# Greater than or equal for string comparisons
gtoe() {
    [[ "${1}" > "${2}" || "${1}" == "${2}" ]]
}
