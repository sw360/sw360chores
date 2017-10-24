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
TARGET="liferay-portal-tomcat-6.2-ce-ga5-20151119152357409.zip"

if [ ! -f "$DIR/$TARGET" ]; then
    curl -OskLC - 'https://downloads.sourceforge.net/project/lportal/Liferay%20Portal/6.2.4%20GA5/liferay-portal-tomcat-6.2-ce-ga5-20151119152357409.zip'
else
    echo "... the file $TARGET already exists: skip"
fi
