#!/bin/sh
# Author: m3adow
# Description: 
# 	This is intended as assistance when (mis)using the Consul tags as KV-store for attributes.
#		To properly use this, at least one of the instances tags needs to be formatted like this:
#			%%key1=value1%key2=value2%etc=etc%%
#		You can then pass the wanted key and the tags to the script in a ctmpl file:
#			{{ $tags := .Tags | join " "}} 
#			{{plugin "/plugins/extract_tag_kv.sh" "key1" $tags}}
#		Result:
#			value1
# When not finding anything, the script normally returns an empty value, if you want to change
# that, you can set the wanted default return as third parameter.

set -e
set -u
set -o pipefail


TARGET="${1:-}"
TAGS="${2:-}"
NULL_RESULT="${3:-}"

if [ -z "${TARGET}" -o -z "${TAGS}" ]
then
	printf "%s" "${NULL_RESULT}"
	exit
fi

for TAG in $TAGS
do
	if [ "$(echo "$TAG"|grep -c -E '%%.*%%')" -gt 0 ]
	then
		for KV in $(echo "$TAG"|tr -s "%" " ")
		do
			KEY=$(echo "$KV"|sed -re 's/^([^=]+)=.*$/\1/')
			VALUE=$(echo "$KV"|sed -re 's/^[^=]+=(.*)$/\1/')

			# replaced by sed
			#KEY=$(printf "$KV"|cut -d '=' -f1)
			#VALUE=$(printf "$KV"|cut -d '=' -f2)
			if [ "$KEY" = "$TARGET" ]
			then
				printf "$VALUE"
				exit
			fi
		done
	fi
done
printf "${NULL_RESULT}"
