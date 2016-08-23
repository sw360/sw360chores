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

if [ "$1" == "--dry-run" ]; then
    shift
    DRY_RUN=true
fi

if [ "$1" == "--ignore-configuration-file" ]; then
    shift
else
    [ -f "$DIR/configuration.env" ] && source "$DIR/configuration.env"
fi

DRY_RUN=${DRY_RUN:-false}
DEV_MODE=${DEV_MODE:-false}
CVE_SEARCH=${CVE_SEARCH:-false}
HTTPS_COUCHDB=${HTTPS_COUCHDB:-false}

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
   - \`--dry-run\` (only echo and do not run cmd)
   - \`--ignore-configuration-file\` (do not build the \`-f\` part automatically)
   - \`--save-images\` (saves all images related to the current configuration to \`./_images/\`)
   - \`--load-images\` (loads all images in \`./_images/\` into docker)

All allowed ways of calling this script:
     \$ $0 [--dry-run] [--ignore-configuration-file] <some docker-compose arguments>
     \$ $0 [--save-images]
     \$ $0 [--load-images]

Example calls of this script as docker-compose wrapper:
     \$ DEV_MODE=true $0 up -d
     \$ $0 restart sw360
     \$ $0 logs -f
     \$ $0 --ignore-configuration-file up \$app (used by systemd)

The environmental variables / inputs are set to
    DRY_RUN=$DRY_RUN
    DEV_MODE=$DEV_MODE
    CVE_SEARCH=$CVE_SEARCH

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
# run the command:
if [ "$1" == "--save-images" ]; then
    mkdir -p "$DIR/_images"
    cmdDockerCompose="$cmdDockerCompose ps -q"
    $cmdDockerCompose |\
        while read -r containerId; do
            cmdForImage="$cmdDocker inspect --format {{.Config.Image}} $containerId"
            image="$($cmdForImage)"
            echo "Save image $image to ./_images/$image.tar ..."
            $cmdDocker save -o "$DIR/_images/$image.tar" "$image"
        done
elif [ "$1" == "--load-images" ]; then
    for imageArchive in $DIR/_images/*.tar; do
        echo "load image $(basename "$imageArchive") ..."
        $cmdDocker load -i "$imageArchive"
    done
else
    cmdDockerCompose="$cmdDockerCompose $*"
    if [ "$DRY_RUN" = true ]; then
        echo "$cmdDockerCompose"
    else
        $cmdDockerCompose
    fi
fi
