#!/usr/bin/env bash

# Copyright Bosch.IO GmbH, 2020.
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
 -pl 'build-configuration,libraries,libraries/lib-datahandler,libraries/commonIO'
mvn -f $SW360_DEV/pom.xml package -P deploy -Dbase.deploy.dir=$builddir -DskipTests \
 -pl 'build-configuration,libraries,rest,rest/rest-common,rest/resource-server'

(cd $builddir/tomcat && ../../create-slim-war-files.sh)

docker build -t sw360/rest -f Dockerfile_local "$@" .
