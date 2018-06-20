#!/bin/bash

function getMerged() {
	git branch --merged | grep -v ^*
}

function removeMerged() {
	getMerged | xargs --no-run-if-empty -n4 git branch -d
}

function checkOpts() {
	while getopts ":n" opt; do
	  case $opt in
	    n) 
	    	for i in $(getMerged); do
	        	echo " [would delete] $i"
	    	done
	    	exit 0;
		;;
	    \?) 
			echo "Invalid option: -$OPTARG" >&2 
			exit 1 
		;;
	  esac
	done	
}

function main() {
	checkOpts "$@";
	removeMerged;
}

main "$@"