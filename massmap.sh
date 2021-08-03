#!/usr/bin/env bash

usage() {
	echo "Usage:\tmassmap <options> ip"
	echo -e "\n\n<OPTIONS>\n"
	echo -e "-e\tInterface to scan on"
}

# check if masscan is installed
if ! [ -x "$(command -v masscan)" ]; then
	echo 'Error: Masscan is not installed.' >&2
	exit 1
fi

# check if nmap is installed
if ! [ -x "$(command -v nmap)" ]; then
	echo 'Error: Nmap is not installed.' >&2
	exit 1
fi

if [ "$EUID" -ne 0 ]; then
	echo "Error: This process requires root privilege.";
	exit 1
fi

while getopts ":e:" opt; do
	case ${opt} in 
		e )
			interface=$OPTARG
		;;
		\? )
		echo "Invalid option: -$OPTARG" 1>&2
		usage
		exit 1
		;;
	esac
done
shift $((OPTIND -1))

if [ $# -ne 1 ]; then
	usage
	exit 1
fi

target=$1


if test -f "paused.conf"; then
	rm -f paused.conf
fi

# running masscan
echo "running masscan ..."
masscan -e $interface --ports 1-65535 --rate 1000 $target | tee masscan
wait
nmap_ports=$(awk '{print $4}' masscan | cut -d'/' -f1 | tr '\n' ',' | sed 's/.$//')
nmap -sC -sV -T4 -A -p "${nmap_ports}" "$target" -oN nmap_scan
