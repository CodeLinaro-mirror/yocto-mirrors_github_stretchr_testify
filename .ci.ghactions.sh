#!/usr/bin/env bash

# Verify that hashes of GitHub actions match the declared tag in attached comment
#
# Author: Olivier Mengué

set -euo pipefail

declare -A seen

status=0

for w in .github/workflows/*.yml
do
	#sed -n -e '/uses:/ s!uses: \([^@]*\)@\([^ #]*\)\(  *# \(v.*\)\)?$!\1 \2 \4!p' "$w" | while read action hash tag
	sed -n -e '/uses: / s!^ *-\{0,1\} uses: \([^@]*\)@\([0-9a-f][0-9a-f]*\) *# *\(v.*\)$!\1 \2 \3!p' "$w" | while read action hash tag
	do
		if (( ${seen[$action-$hash]:-0} )); then
			printf "\e[1;32m%s: %s@%s == %s\e[m\n" "$w" "$action" "$tag" "$hash"
			continue
		fi
		seen[$action-$hash]=1

		if ! eval "$( curl -s -H "Accept: application/vnd.github+json" \
			https://api.github.com/repos/$action/commits/$tag | jq -r '.sha == "'$hash'"' )"; then
			printf "\e[1;31m%s: %s@%s != %s\e[m\n" "$w" "$action" "$tag" "$hash"
			status=1
		else
			printf "\e[1;32m%s: %s@%s == %s\e[m\n" "$w" "$action" "$tag" "$hash"
		fi
	done
done

exit $status
