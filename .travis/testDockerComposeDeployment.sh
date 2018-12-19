#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Copyright Siemens AG, 2017.
# Copyright Bosch Software Innovations GmbH, 2017.
# Part of the SW360 Portal Project.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved. This file is offered as-is,
# without any warranty.
# -----------------------------------------------------------------------------
set -e

. "$( cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd )/assertions.sh"

################################################################################
# run

## Tomcat
assertTomcat
# if [ "$DEV_MODE" == "true" ]; then
#     assertLiferayViaHTTP
# fi
assertLiferayViaNginx
# if [ "$DEV_MODE" != "true" ]; then
#     assertNoTomcatDebugPort
# fi

## Couchdb
assertCouchdb
# if [ "$DEV_MODE" == "true" ]; then
#     assertCouchdbViaHTTP
# fi
