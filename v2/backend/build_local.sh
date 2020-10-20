#!/usr/bin/env bash

# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

set -e
if [ -z "$1" ]; then
  echo "Usage: $0 sw360ProjectRoot"
  exit 1
fi
SW360_DEV=$1
shift

rm -rf build
builddir=$(pwd)/build

mvn -f $SW360_DEV/pom.xml package -P deploy -Dbase.deploy.dir=$builddir -DskipTests \
 -pl '!rest,!rest/rest-common,!rest/authorization-server,!rest/resource-server,!frontend,!frontend/sw360-portlet,!frontend/liferay-theme,!libraries/importers'

(cd $builddir/tomcat && ../../create-slim-war-files.sh)

docker build -t sw360/backend -f Dockerfile_local "$@" .
