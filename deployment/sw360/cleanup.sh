#!/usr/bin/env bash

# Copyright Bosch Software Innovations GmbH, 2017.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# This script invokes the building of the dependency package required by
# sw360 and places it into the sw360 folder.

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd )"
rm "$DIR/sw360_dependencies.tar.gz" || true
