#!/usr/bin/env bash

# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

################################################################################
# handle environmental variables and other inputs

if [ "$1" == "--ignore-configuration-file" ]; then
    shift
else
    [ -f "$DIR/configuration.env" ] && source "$DIR/configuration.env"
fi

DEV_MODE=${DEV_MODE:-false}
CVE_SEARCH=${CVE_SEARCH:-false}
HTTPS_COUCHDB=${HTTPS_COUCHDB:-false}
BACKUP_FOLDER=${BACKUP_FOLDER:-./_backup}

type "docker-compose" &> /dev/null || {
    echo "this script needs docker-compose to be installed within \$PATH"
    exit 1
}

################################################################################
# help message

if [ "$#" -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    cat <<EOF
This is a wrapper around docker-compose which adds
 - automatic sourcing of the file ./proxy.env to docker-compose calls
 - automatic adding sudo if user is not in group docker or \`docker status\` fails
 - automatic adding of the configuration files depending on the configuration, i.e.
   - the environmental variables
     \`DEV_MODE\`   (defaults to "false")
     \`CVE_SEARCH\` (defaults to "false")
     these environmental variables can also be defined in the file \`configuration.env\`

Can be used in the same way as the direct docker-compose call up to minor changes:
 - one does not have to specify the compose files via the \`-f\` parameter
 - adds the following potential first (and only) arguments
   - \`--ignore-configuration-file\` (do not build the \`-f\` part automatically)
   - \`--save-images\` (saves all images related to the current configuration to \`./_images/\`)
   - \`--load-images\` (loads all images in \`./_images/\` into docker)
   - \`--backup` (backups all volumes to the path defined in \$BACKUP_FOLDER)
   - \`--restore` (restores all volumes from the path defined in \$BACKUP_FOLDER)

All allowed ways of calling this script:
- generic calling of docker-compose commands
     \$ $0 [--ignore-configuration-file] <some docker-compose arguments>
- import and export of images
     \$ $0 --save-images
     \$ $0 --load-image]
- backup and restore of volume data
     \$ $0 --backup
     \$ $0 --restore

Example calls of this script as docker-compose wrapper:
     \$ DEV_MODE=true $0 up -d
     \$ $0 restart sw360
     \$ $0 logs -f

The environmental variables / inputs are set to
    DRY_RUN=$DRY_RUN
    DEV_MODE=$DEV_MODE
    CVE_SEARCH=$CVE_SEARCH
    BACKUP_FOLDER=$BACKUP_FOLDER

EOF
    exit 0
fi

################################################################################
# compose the command:
addSudoIfNeeded() {
    docker info &> /dev/null || {
        echo "sudo"
    }
}

cmdDocker="$(addSudoIfNeeded) env $(grep -v '^#' proxy.env | xargs) docker"
cmdDockerCompose="${cmdDocker}-compose -f $DIR/docker-compose.yml"
[ "$DEV_MODE" == "true" ] && cmdDockerCompose="$cmdDockerCompose -f $DIR/docker-compose.dev.yml"
[ "$CVE_SEARCH" == "true" ] && cmdDockerCompose="$cmdDockerCompose -f $DIR/docker-compose.cve-search-server.yml"
[ "$HTTPS_COUCHDB" == "true" ] && cmdDockerCompose="$cmdDockerCompose -f $DIR/docker-compose.couchdb-https.yml"

################################################################################
# helper functions
saveImages() {
    mkdir -p "$DIR/_images"
    cmdDockerCompose="$cmdDockerCompose ps -q"
    $cmdDockerCompose |\
        while read -r containerId; do
            cmdForImage="$cmdDocker inspect --format {{.Config.Image}} $containerId"
            image="$($cmdForImage)"
            echo "Save image $image to ./_images/$image.tar ..."
            $cmdDocker save -o "$DIR/_images/$image.tar" "$image"
        done
}

loadImages() {
    for imageArchive in $DIR/_images/*.tar; do
        echo "load image $(basename "$imageArchive") ..."
        $cmdDocker load -i "$imageArchive"
    done
}

backupVolumeOf() {
    containerId=$1
    containerName=$2
    volume=$3

    echo -e "\t...backup volume ${volume} of ${containerName}"
    backupFileName="${containerName}_$(echo $volume | sed 's%/%_%g').tar"
    $cmdDocker run --rm \
               --volumes-from $containerId \
               -v "$(realpath $BACKUP_FOLDER):/backup" \
               debian:jessie \
               tar cf "/backup/$backupFileName" ${volume}
}

backupAllVolumesOf() {
    containerId=$1

    containerName=$($cmdDocker inspect -f '{{ .Name }}' $containerId |\
                           sed 's%^/%%g')
    echo -e "backup ${containerName}"

    volumes=$($cmdDocker inspect -f '{{ .Config.Volumes }}' $containerId)
    if [[ ! "$volumes" = "map["*"]" ]]; then
        echo "there were problems with recieving the list of volumes: $volumes"
        exit 1
    else
        volumes=( $(echo $volumes |\
                           sed 's/map\[\(.*\)\]/\1/' |\
                           sed 's/:{}//g') )

        for volume in "${volumes[@]}"; do
            backupVolumeOf $containerId $containerName $volume
        done
    fi
}

backup() {
    mkdir -p "$BACKUP_FOLDER"
    cmdDockerCompose="$cmdDockerCompose ps -q"
    containerIds=( $($cmdDockerCompose | xargs) )
    for containerId in "${containerIds[@]}"; do
        backupAllVolumesOf $containerId
    done
}

restoreVolumeOf() {
    containerId=$1
    containerName=$2
    volume=$3

    backupFileName="${containerName}_$(echo $volume | sed 's%/%_%g').tar"
    if [[ ! -f "$BACKUP_FOLDER/$backupFileName" ]]; then
        echo "there is no backup file $backupFileName"
    else
        read -p "restore the volume ${volume} of ${containerName}? " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "\t...restore the volume ${volume} of ${containerName}"
            $cmdDocker run --rm \
                       --volumes-from $containerId \
                       -v "$(realpath $BACKUP_FOLDER):/backup" \
                       debian:jessie \
                       tar -xf "/backup/$backupFileName" -C /
        fi
    fi
}

restoreAllVolumesOf() {
    containerId=$1

    containerName=$($cmdDocker inspect -f '{{ .Name }}' $containerId |\
                           sed 's%^/%%g')
    echo -e "restore ${containerName}"

    volumes=$($cmdDocker inspect -f '{{ .Config.Volumes }}' $containerId)
    if [[ ! "$volumes" = "map["*"]" ]]; then
        echo "there were problems with recieving the list of volumes: $volumes"
        exit 1
    else
        volumes=( $(echo $volumes |\
                           sed 's/map\[\(.*\)\]/\1/' |\
                           sed 's/:{}//g') )

        for volume in "${volumes[@]}"; do
            restoreVolumeOf $containerId $containerName $volume
        done
    fi
}

restore() {
    if [[ ! -d "$BACKUP_FOLDER" ]]; then
        echo "the backup ($BACKUP_FOLDER) folder does not exist"
        exit 1
    fi
    cmdDockerCompose="$cmdDockerCompose ps -q"
    containerIds=( $($cmdDockerCompose | xargs) )
    for containerId in "${containerIds[@]}"; do
        restoreAllVolumesOf $containerId
    done
}

################################################################################
# run the command:
if [ "$1" == "--save-images" ]; then
    saveImages
elif [ "$1" == "--load-images" ]; then
    loadImages
elif [ "$1" == "--backup" ]; then
    backup
elif [ "$1" == "--restore" ]; then
    restore
else
    cmdDockerCompose="$cmdDockerCompose $*"
    $cmdDockerCompose
fi
