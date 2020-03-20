#!/bin/bash
###
## This script will do an incremental snapshot
## with an diff for of the last 7 changes.
##
## requiremds: rsync megatools
###

function getExcludes() {
    local items=(
        '/dev/*'
        '/proc/*'
        '/sys/*'
        '/tmp/*'
        '/run/*'
        '/mnt/*'
        '/media/*'
        '/lost+found'
    )
    for i in $(find /var/log -type d); do
            items+=($(printf '%s/*.1'  "$i"))
            items+=($(printf '%s/*.gz' "$i"))
    done
    echo "${items[@]}" | tr ' ' "\n";

}

function getBackupDir() {
    local day=$(date +%A)
    echo diff-${day,,}
}

function pack() {
    local backup_dir=$(getBackupDir)
    if [ -e "stage" ]; then
        rm -rf "stage"
    fi
    mkdir stage
    tar -zcf stage/snapshot.tar.gz snapshot --transform='s/snapshot//g'
    tar -zcf stage/${backup_dir}.tar.gz ${backup_dir} --transform="s/${backup_dir}//g"
}

function sync() {
    local backup_dir=${1}/$(getBackupDir)
    if [ -e "$backup_dir" ]; then
        rm -rf "$backup_dir"
    fi
    getExcludes | rsync \
        --quiet \
        --one-file-system \
        --archive \
        --hard-links \
        --acls \
        --delete \
        --backup-dir=${backup_dir} \
        --xattrs \
        --sparse \
        --exclude-from=- \
        / \
       ${1}/snapshot
}

function push() {
    local remote_path=/Root/backup

    for i in $(ls stage); do
        if [ "$(megals ${remote_path}/${i})" != "" ]; then
            megarm "${remote_path}/${i}"
        fi
        megaput --no-progress ${i} --path ${remote_path}
    done

    rm -rf stage
}

function main() {
    # exit direct on errors
    set -ue

    # set low priority
    ionice -c 3 -p $$
    renice +12  -p $$

    # move current working directory
    cd $1
    
    ## remove downloaded packes
    apt-get clean

    sync $1
    pack $1
    push $1
}

main "/media/backup"
