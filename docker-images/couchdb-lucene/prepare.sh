#!/usr/bin/env bash

# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd )"
BRANCH="v2.1.0"
TARGET="couchdb-lucene-2.1.0-dist.zip"

if [ ! -f "$DIR/$TARGET" ]; then
    ################################################################################
    # compose the command:
    addSudoIfNeeded() {
        docker info &> /dev/null || {
            echo "sudo"
        }
    }

    cmdDocker="$(addSudoIfNeeded) env $(grep -v '^#' $DIR/../../proxy.env | xargs) docker"

    ################################################################################
    # create and place the file $TARGET
    TMP=$(mktemp -d)
    env $(grep -v '^#' "$DIR/../proxy.env" | xargs) \
        git clone --branch $BRANCH --depth 1 https://github.com/rnewson/couchdb-lucene "$TMP/couchdb-lucene.git"

    $cmdDocker pull maven:3-jdk-8-alpine
    $cmdDocker run -i \
               --cap-drop=all --user "${UID}" \
               -v "$TMP/couchdb-lucene.git:/couchdb-lucene" \
               --env http_proxy \
               --env https_proxy \
               --env no_proxy \
               --env MAVEN_CONFIG=/tmp/ \
               -w /couchdb-lucene \
               maven:3-jdk-8-alpine \
               mvn
    cp "$TMP/couchdb-lucene.git/target/$TARGET" "$DIR"
    rm -rf "$TMP"
else
    echo "... the file $TARGET already exists: skip"
fi
