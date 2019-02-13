#!/bin/bash
##
## @author Philip Bergman <pbergman@live.nl>
##
## a node installer that gives posibility to install
## diferent versions of node useing update-alternatives
##
## example:
##   node_installer -v v10.15.1

function init() {
	[ ! -d "$1" ] && { mkdir -p $1; echo "created $1"; }
	[ -d "$1/node-${2}-${3}" ] && { echo "version ${2}-${3} is allready installed"; exit 1; } 
}

function usage() {
	echo "usage: ${0##*/} [-h] [-v <v8.15.0)>] [-d <linux-x64>] [-b </usr/local/lib/nodejs>]"
	exit 1
}

function download() {
	printf "downloading node version %s-%s to %s\n" "$2" "$3" "$1"
	wget --show-progress "https://nodejs.org/download/release/${2}/node-${2}-${3}.tar.gz" -qcO - | tar -xzC $1
}

function install() {
	update-alternatives --install /usr/local/bin/node node $1/node-${2}-${3}/bin/node ${2//[!0-9]/}
	update-alternatives --install /usr/local/bin/npm npm $1/node-${2}-${3}/bin/npm ${2//[!0-9]/}
	update-alternatives --install /usr/local/bin/npx npx $1/node-${2}-${3}/bin/npx ${2//[!0-9]/}
}

function main() {
	local version=v8.15.0
	local distro=linux-x64
	local lib_dir=/usr/local/lib/nodejs
	while getopts ":d:hv:d:" o; do
		case "${o}" in
		    b) lib_dir=${OPTARG} ;;
		    d) distro=${OPTARG} ;;
		    v) version=${OPTARG} ;;
		    h) usage ;;
		    *) usage ;;
		esac
	done
	init $lib_dir $version $distro
	download $lib_dir $version $distro
	install $lib_dir $version $distro
}

main "$@"