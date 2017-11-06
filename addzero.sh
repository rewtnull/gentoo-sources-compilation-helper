addzero() {

    local inver="${1}"

    # insert a zero before a single digit if it's not preceding a digit,
    # and it's followed by -gentoo

    # using perl as a replacement to grep -P (one dependency less)
    if [[ $(echo "${inver}" | perl -ne '/(?<!\d)\d(?=-gentoo)/ && print') ]]; then
	echo "${inver}" | perl -pe 's/(?<a>.*\.)/$+{a}0/'
    else
	echo "${inver}"
    fi
}
