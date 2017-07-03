#!/usr/bin/env bash

# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# This script invokes the building of the dependency package required by
# sw360 and places it into the sw360 folder.

set -ex
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd )"
TARGET="sw360_dependencies.tar.gz"

if [ ! -f "$DIR/$TARGET" ]; then
    PACKAGE_DIR="$DIR/../../packaging"
    if [ ! -f "$PACKAGE_DIR/sw360packager.Dockerfile" ]; then
        echo "can not find the packaging Dockerfile"
        exit 1
    fi

    ############################################################################
    # compose the command:
    addSudoIfNeeded() {
        docker info &> /dev/null || {
            echo "sudo"
        }
    }

    cmdDocker="$(addSudoIfNeeded) env $(grep -v '^#' $DIR/../proxy.env | xargs) docker"

    ############################################################################
    # create and place the file ./sw360_dependencies.tar.gz
    if [ -z ${http_proxy+x} ]; then export http_proxy=""; fi
    if [ -z ${https_proxy+x} ]; then export https_proxy=""; fi
    if [ -z ${no_proxy+x} ]; then export no_proxy=""; fi

    $cmdDocker build \
               --build-arg http_proxy \
               --build-arg https_proxy \
               --build-arg no_proxy \
               -t sw360/sw360packager \
               --rm=true --force-rm=true \
               - < "$PACKAGE_DIR/sw360packager.Dockerfile"
    $cmdDocker run -i \
               --env http_proxy \
               --env https_proxy \
               --env no_proxy \
               -v "${PACKAGE_DIR}:/sw360chore" \
               -v "${DIR}:/sw360chore/_output" \
               -w /sw360chore \
               sw360/sw360packager \
               chroot --userspec=$(id -u):$(id -g) --skip-chdir / \
               rake package:tar
else
    echo "... the file $TARGET already exists: skip"
fi
