gtoe() {
    local first="${1}"
    local second="${2}"

    first="$(addzero "${first}")" # if there's only one digit at the end of the version string, add a 0 before it
    second="$(addzero "${second}")"

    [[ "$first}" > "${second}" || "${first}" == "${second}" ]]
}
