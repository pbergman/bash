#!/bin/bash

function getRemoteMerged() {
        git branch -r --merged  | grep -Ev '(release\/[0-9]{1,}.[0-9]{1,}.x|HEAD)$' | sed 's/origin\///'
}

function removeRemoteMerged() {
	getRemoteMerged | xargs --no-run-if-empty -n1 -P4 git push origin --delete
}

function checkOpts() {
	while getopts ":n" opt; do
	  case $opt in
	    n)
		getRemoteMerged | xargs -n1 --no-run-if-empty -i echo " [would delete] {}"
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
	removeRemoteMerged;
}

main "$@"
