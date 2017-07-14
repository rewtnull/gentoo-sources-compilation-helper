error() {
    { echo -e "${@}\n" 1>&2; exit 1; }
}
