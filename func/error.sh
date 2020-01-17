error() {
    { echo -e "${redfg}*${off} ${*}\n" 1>&2; exit 1; }
}
