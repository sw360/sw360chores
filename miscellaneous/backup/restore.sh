#!/usr/bin/env bash
# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
set -e

################################################################################
# configuration

host=localhost
# user=sw360
# password=sw360fossy

if [ $1 ] && [ -d $1 ]; then
    backupDir=$1
else
    backupDir="_backup/last"
fi

################################################################################
# preperation
set -e
cd $(dirname $0)
DIR=$(pwd)
exec 1 | tee "$backupDir/$(basename $0).log"
exec 2 | tee "$backupDir/$(basename $0).log"

################################################################################
# functions
updateCouchdbDump() {
    mkdir -p bin
    curl https://raw.githubusercontent.com/danielebailo/couchdb-dump/master/couchdb-backup.sh > bin/couchdb-backup.sh
    chmod +x bin/couchdb-backup.sh
}

restore() {
    jsonFile=$1
    jsonBasename=$(basename $jsonFile)
    db=${jsonBasename%.json}

    echo "restore db $db"

    #create the db
    dbCreationOutput=$(curl -X PUT "http://${host}:5984/${db}")
    if [[ "$dbCreationOutput" = *"\"ok\":true"* ]]; then
        # backup the data
        cmd="bash ${DIR}/bin/couchdb-backup.sh -c -r -H $host -d $db -f $jsonFile"
        if [ $user ]; then
            cmd="$cmd -u $user"
            if [ $password ]; then
                cmd="$cmd -p $password"
            fi
        fi
        $cmd || {
            echo "ERROR: $jsonFile restore failed"
        }
    else
        echo "ERROR: while creating the db $db: $dbCreationOutput"
    fi
}

restoreAll() {
    for jsonFile in $backupDir/*.json; do
        restore $jsonFile
    done
}

################################################################################
# do the restore

updateCouchdbDump
restoreAll
