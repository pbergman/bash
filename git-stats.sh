#!/bin/bash
#
# @author Philip Bergman <pbergman@live>
#
# this script helps to get some stats about an commit, it wil print
# the (remote and local) branches and tags that contains this commit, 
# the count  of commits behind and ahead and all logs till head. By 
# default it uses the $(git remote)/HEAD (remote HEAD) to check against

export HEAD=$(git remote)/HEAD
export VERBOSE=false
export SHOW_MERGES=true
export SCRIPT_SELF=${0##*/}
export ARGS

function printTagContains() {
	local tags=($(git tag --contains $1))
	local tags_count=${#tags[@]}
	if (( $tags_count > 0 )); then
		printf "tags that contains %s\n" "$1"
		for ((i=0; i<$tags_count; i++)); do
			if [[ "$i" == "$(($tags_count-1))" ]]; then 
				echo "└── ${tags[i]}"
				echo ""
			else 
				echo "├── ${tags[i]}"
			fi
		done
	fi
}

function printTagPoints() {
	local tags=($(git tag --points-at $1))
	local tags_count=${#tags[@]}
	if (( $tags_count > 0 )); then
		printf "tag %s point at %s\n\n" "$tags" "$1"
	fi
}

function printBranch() {
	local hash=$1
	local count=$(git branch -a --contains $hash | wc -l)
	if (( $count > 0 )); then
		printf "all branches that contains %s\n\n" "$hash"
		printBranchContains $hash
		printBranchContains $hash 1	
	fi	
}

function printBranchContains() {
	local hash=$1
	local remote=$(git remote)
	if [[ -z "$2" ]] ||  [[ "$2" == 0 ]]; then 
		local isRemote=0
		local branches=($(git branch --contains $hash | awk '{print $NF}'))
		local prefix=""
	else 
		local isRemote=1
		local branches=($(git branch --remotes --contains $hash | awk '{print $NF}'))
		local prefix="${remote}/"
	fi
	local branch_count=${#branches[@]}
	if (( $branch_count > 0 )); then		
		if [ "$isRemote" == 1 ]; then
			echo "$remote"
		else 
			echo "local"
		fi
		for ((i=0; i<branch_count; i++)); do
			if [[ "$i" == "$(($branch_count-1))" ]]; then 
				echo "└── ${branches[i]#"$prefix"}"
				echo ""
			else 
				echo "├── ${branches[i]#"$prefix"}"
			fi
		done
	fi
}

function printBehindAhead() {	
	local hash=$1
	local remote=$(git remote)
	local opts="rev-list --count --left-right"
	if [ "$SHOW_MERGES" == false ]; then
		opts="$opts --no-merges"
	fi
	local stats=($(git $opts ${hash}..${HEAD}))
	printf "%s is %d commits behind and %d commits ahead with %s\n\n" "$hash" "${stats[0]}" "${stats[1]}" "$HEAD";
}


function usage() { 
	printf "Usage: %s [-v|--verbose] [-d|--debug] [-n|--no-merges] [-H|--head <HEAD>] [-h|--help] <HASH>\n" "$SCRIPT_SELF" 1>&2; exit 1; 
}

function checkOpts() {
	eval set -- $(getopt -o dvnhH: --long debug,verbose,no-merges,help,head: -- "$@")
	while true; do
	  case "$1" in	  
        -h | --help ) usage; exit 2 ;;
        -v | --verbose ) VERBOSE=true; shift ;;
        -d | --debug ) set -x; shift ;;
        -n | --no-merges ) SHOW_MERGES=false; shift ;;
        -H | --head ) HEAD="$2"; shift 2 ;;
        -- ) shift; break ;;
        * ) break ;;
	  esac
	done
	ARGS=$@
}

function printLogs() {
	local opts="log --raw --decorate"
	if [ "$SHOW_MERGES" == false ]; then
		opts="$opts --no-merges"
	fi
	if [ "$VERBOSE" == true ]; then
		opts="$opts --patch"
	else 
		opts="$opts --pretty=oneline"
	fi
	git $opts $1..${HEAD}
}

function main() {
	checkOpts "$@"	
	local hash=$(git rev-parse --short "$ARGS")
	if [ -z "$hash" ]; then
		printf "invalid hash: '%s'\n" "$ARGS"
		usage
	fi
	printTagPoints $hash
	printTagContains $hash
	printBranch $hash
	printBehindAhead $hash
	printLogs $hash
}

main "$@"