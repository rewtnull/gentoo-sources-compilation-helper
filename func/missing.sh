# missing(look_for required_package)
missing() {
    [[ $(type -p ${1}) ]] || error "${1} is missing. Install \033[1m${2}\033[m"
}
