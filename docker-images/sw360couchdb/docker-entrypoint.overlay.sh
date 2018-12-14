#!/usr/bin/env bash

# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

if [ "$COUCHDB_LUCENE_HOST" ]; then
    sed -i -r 's/\[httpd_global_handlers\]/[httpd_global_handlers]\n_fti = {couch_httpd_proxy, handle_proxy_req, <<"http:\/\/'"$COUCHDB_LUCENE_HOST"':5985">>}/' /usr/local/etc/couchdb/local.ini
fi

if [ "$(ls -A /usr/local/var/lib/couchdb)" ]; then
    echo "Data directory not empty, will not provision."
else
    if [ "$(ls -A /initial-data)" ]; then
        cp -R /initial-data/* /usr/local/var/lib/couchdb
        echo "Provisioned container with data from /initial-data"
    fi
fi

exec /docker-entrypoint.sh "$@"

