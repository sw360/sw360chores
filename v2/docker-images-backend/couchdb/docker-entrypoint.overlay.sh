#!/usr/bin/env bash

# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

COUCH_HOME=/opt/couchdb
COUCH_DATA=$COUCH_HOME/data

if [ "$COUCHDB_LUCENE_HOST" ]; then
    sed -i -r 's/\[httpd_global_handlers\]/[httpd_global_handlers]\n_fti = {couch_httpd_proxy, handle_proxy_req, <<"http:\/\/'"$COUCHDB_LUCENE_HOST"':5985">>}/' $COUCH_HOME/etc/local.ini
fi

if [ "$(ls -A $COUCH_DATA)" ]; then
    echo "Data directory not empty, will not provision."
else
    if [ "$(ls -A /initial-data)" ]; then
        cp -R /initial-data/* $COUCH_DATA
        echo "Provisioned container with data from /initial-data"
    fi
fi

COUCHDB_USER_FILE=/run/secrets/COUCHDB_USER
if [ -f "$COUCHDB_USER_FILE" ]; then
    export COUCHDB_USER=$(cat "$COUCHDB_USER_FILE")
fi
COUCHDB_PASSWORD_FILE=/run/secrets/COUCHDB_PASSWORD
if [ -f "$COUCHDB_PASSWORD_FILE" ]; then
    export COUCHDB_PASSWORD=$(cat "$COUCHDB_PASSWORD_FILE")
fi

exec /docker-entrypoint.sh "$@"

