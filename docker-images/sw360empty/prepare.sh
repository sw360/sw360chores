#!/usr/bin/env bash

# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

set -e
cd "$(dirname "${BASH_SOURCE[0]}" )"
TARGET="sw360-liferay.tar.gz"

if [ ! -f "$TARGET" ]; then
    ../../miscellaneous/prepare-liferay/prepare.sh
    cp ../../miscellaneous/prepare-liferay/$TARGET ./
else
    echo "... the file $TARGET already exists: skip"
fi
