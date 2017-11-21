error() {
    { echo -e "\n\e[91m*\e[0m ${*}\n" 1>&2; exit 1; }
}
