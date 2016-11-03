#!/bin/bash

set -e

indent="  "

for file in "$@"
do
	echo "$file"

	# trim trailing space
	sed -i 's/[[:space:]]*$//' "$file"

	# replace first space indentation by tab
	sed -i "s/^${indent}/\t/g" "$file"

	# replace up to 10 following levels by tab
	for i in 1 2 3 4 5 6 7 8 9 0
	do
		sed -i "s/\t${indent}/\t\t/g" "$file"
	done

	# collapse inline whitespace indentation
	sed -i "s/  / /g" "$file"

done
