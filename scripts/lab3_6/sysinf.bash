#!/bin/bash
if [[ "$1" == "-v" || "$1" == "--version" ]];
then
	echo "Kernel version:" $( uname -r )
	lsb_release -a
elif [[ "$1" == "-i" || "$1" == "--ipaddress" ]];
then
	ip addr | awk '/inet / {print $2}/: / {print $2}'

elif [[ "$1" == "-m" || "$1" == "--macaddress" ]];
then
	ip addr | awk '/link\// {print $2} /: / {print $2}'
else
	if [[ ! -z "$1" && ! "$1" == "-h" && ! "$1" == "--help" ]]; then
		echo "sysinf: invalid option $1"
	fi
	echo "Usage: sysinf [option]"
	echo "sysinf              Display this"
	echo ""
	echo "Program options:"
	echo "   -h, --help           Display this."
	echo "   -v, --version        Prints linux version"
	echo "   -i, --ipaddress      Prints ipaddress"
	echo "   -m, --macaddress     Prints macaddress"
fi
