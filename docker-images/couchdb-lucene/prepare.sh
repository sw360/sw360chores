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

CLEANUP=false
NO_DOCKER=false
NET_HOST=false

for arg in "$@"
do
  if [[ $arg == "--cleanup" ]]; then
    CLEANUP=true
  elif [[ $arg == "build-without-docker" ]]; then
    NO_DOCKER=true
  elif [[ $arg == "--net-host" ]]; then
    NET_HOST=true
  fi    
done

if [[ "$CLEANUP" == true ]]; then
    if [ -f "$TARGET" ]; then
        rm "$TARGET"
    fi
    exit 0
fi

if [ ! -f "$DIR/$TARGET" ]; then
    if [[ -f $DIR/../../configuration/proxy.env ]]; then
        source $DIR/../../configuration/proxy.env
    fi

    ################################################################################
    # create and place the file $TARGET

    TMP=$(mktemp -d ${TMPDIR:-/tmp}/tmp.XXXXXXX)
    git clone --branch $BRANCH --depth 1 https://github.com/rnewson/couchdb-lucene "$TMP/couchdb-lucene.git"

    cmdMvn="mvn -DskipTests "
    if [ "$NET_HOST" == false ] || [ "$NO_DOCKER" == true ]; then
      cmdMvn="$cmdMvn -Dhttp.proxyHost=$proxy_host -Dhttp.proxyPort=$proxy_port -Dhttps.proxyHost=$proxy_host -Dhttps.proxyPort=$proxy_port -Dhttp.nonProxyHosts=localhost"
    fi
    echo "DEBUG: $cmdMvn"
    if [[ "$NO_DOCKER" == true ]]; then
        (
            cd "$TMP/couchdb-lucene.git"
            $cmdMvn
        )
    else
        addSudoIfNeeded() {
            docker info &> /dev/null || {
                echo "sudo"
            }
        }

        paramHost=""
        if [ "$NET_HOST" == true ]; then
          paramHost="--net=host"
        fi
        cmdDocker="$(addSudoIfNeeded) docker"
        $cmdDocker pull maven:3.6.3-jdk-11-slim
        $cmdDocker run -i \
                   --cap-drop=all --user "${UID}" \
                   -v "$TMP/couchdb-lucene.git:/couchdb-lucene" \
                   --env MAVEN_CONFIG=/tmp/ \
                   -w /couchdb-lucene \
                   $paramHost \
                   maven:3.6.3-jdk-11-slim \
                   $cmdMvn -Dmaven.repo.local=/tmp/m2/repository
    fi
    cp "$TMP/couchdb-lucene.git/target/$TARGET" "$DIR"
    rm -rf "$TMP"
else
    echo "... the file $TARGET already exists: skip"
fi
