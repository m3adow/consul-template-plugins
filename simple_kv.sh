#!/bin/sh

# Author: m3adow
# Description: 
#		This plugin is intended as a very simple KV store. It can either run in
#		FIFO (first-in-first-out) or LILO (last-in-last-out) mode
#		Basically every KV-pair is stored in a file and either the first or
#		the last value of one key is retrieved.
#
#		Usage:
#		* to store a value, run ./simple_kv.sh "key" "value"
#		* to retrieve a value, run ./simple_kv.sh "key".
#		* By default, the script runs in LILO mode, if you
#			want to retrieve a value in FIFO mode, encapsulate
#			the value in "§": ./simple_kv.sh "§key§"
#
#		When used with no argument, the $FILELOC file is deleted

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
	# exiting with $? != 0 could lead to errors in consul-template
	# todo: Brainstorming if $? > 0 is better anyways
	[ -r "${FILELOC}" ] || exit 0
	# FIFO or LILO?
	if [ $(printf "%s" "${1}"| grep -qE '^§.*§$'; echo $?) -eq 1 ]
	then
		OUTBIN=tac
		KEY=${1}
	else
		OUTBIN=cat
		KEY=${1#§}
		KEY=${KEY%§}
	fi
	VALUE=$(${OUTBIN} "${FILELOC}" |grep -m 1 -E "^${KEY}=" | sed -re 's/^[^=]+=(.*)$/\1/')
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
