# missing(look_for required_package)
missing() {
    type -p "${1}" >/dev/null || error "${1} is missing. install \033[1m${2}\033[m"
}
