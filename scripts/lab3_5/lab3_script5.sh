#!/bin/bash
mypath=$PATH
echo "mypath: "$mypath
myseparatedpath=$(echo $mypath | sed "y/:/\n/")
echo "Separated: "
for path in $myseparatedpath
do
	echo $path
done
