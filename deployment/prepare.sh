#!/usr/bin/env bash

# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# This script invokes the building of the dependency package required by
# sw360 and copies that into the sw360 folder.

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd )"
PACKAGE_DIR="$DIR/../packaging/"
OUTPUT_DIR="$DIR/sw360"
cat "$PACKAGE_DIR/sw360packager.Dockerfile" \
    | docker build -t sw360/sw360packager --rm=true --force-rm=true -
docker run -i \
       -v "${PACKAGE_DIR}:/sw360chore" \
       -v "${OUTPUT_DIR}:/sw360chore/_output" \
       -w /sw360chore sw360/sw360packager \
       gosu $(id -u):$(id -g) rake package:tar
