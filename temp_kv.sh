#!/bin/sh
set -e
set -u
set -o pipefail
#set -x
FILELOC=${FILELOC:-/tmp/temp_kv}

store() {
	# Test if FILELOC is writable
	touch "${FILELOC}" || exit 2
	printf "%s=%s\n" "${1}" "${2}" >> "${FILELOC}"
}

retrieve() {
	[ -r "${FILELOC}" ] || exit 0
	VALUE=$(tac "${FILELOC}" |grep -m 1 -E "^${1}=" | sed -re 's/^[^=]+=(.*)$/\1/')
	printf "%s" "${VALUE}"
}

if [ $# -eq 0 ]
then
	# cleanup mode
	rm -f "${FILELOC}"
elif [ $# -eq 1 ]
then
	if [ $(printf "%s" "${1}" | grep -c "=") -gt 0 ]
	then
		KEY=$(printf "%s" "${1}" | sed -re 's/^([^=]+)=.*$/\1/')
		VALUE=$(printf "%s" "${1}" | sed -re 's/^[^=]+=(.*)$/\1/')
		store "${KEY}" "${VALUE}"
	else
		retrieve "${1}"
	fi
elif [ $# -eq 2 ]
then
	store "${1}" "${2}"
else
	exit 10
fi
