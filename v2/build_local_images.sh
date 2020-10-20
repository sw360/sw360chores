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
  echo "   or: $0 --clean to clean all build folders"
  exit 1
fi

if [ "$1" == "--clean" ]; then
  echo "Cleaning build folders."
  find . -name build -type d -exec rm -rf {} \;
else
  echo "Building local images."
  (cd backend && ./build_local.sh "$@")
  (cd rest && ./build_local.sh "$@")
  (cd liferay-360 && ./build_local.sh "$@")
fi
