#!/bin/bash
# Copyright Bosch Software Innovations GmbH, 2019.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

COUCHDB_USER_FILE=/run/secrets/COUCHDB_USER
if [ -f "$COUCHDB_USER_FILE" ]; then
    export COUCHDB_USER=$(cat "$COUCHDB_USER_FILE")
fi
COUCHDB_PASSWORD_FILE=/run/secrets/COUCHDB_PASSWORD
if [ -f "$COUCHDB_PASSWORD_FILE" ]; then
    export COUCHDB_PASSWORD=$(cat "$COUCHDB_PASSWORD_FILE")
fi

envsubst < /etc/sw360/couchdb.properties.template > /etc/sw360/couchdb.properties

exec catalina.sh run