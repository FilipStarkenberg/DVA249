#!/bin/bash

paths=()
for arg in "$@"
do
	paths+=($arg)
done

for path in ${paths[@]}
do
	if [[ -e "$path" ]]
	then
		if [[ -d "$path" ]]
		then
			echo $path" (Directory)"
		elif [[ -x "$path" ]]
		then
			echo $path" (Executable)"
		elif [[ -L "$path" ]]
		then
			echo $path" (Symbolic link)"
		elif [[ -f "$path" ]]
		then
			echo $path" (Regular file)"
		fi
	else
		echo $path" (Does not exist)"
	fi
done
