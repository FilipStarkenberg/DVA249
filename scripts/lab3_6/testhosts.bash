#!/bin/bash
hosts=$( cat hosts.txt | grep -v "^#" | grep . )

for host in ${hosts[@]}
do
	ping $host -c2 > /dev/null 2>&1
	if [ $? -eq 0 ]
	then
		echo $host" -> is up."
	else
		echo $host" -> can't reach host."
	fi
done
