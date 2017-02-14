#!/usr/bin/env bash
# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

################################################################################
# configuration

host=localhost
# user=sw360
# password=sw360fossy

backupDir="_backup/$(date +%F_%T)"

################################################################################
# preperation
set -e
cd $(dirname $0)
DIR=$(pwd)
mkdir -p "$backupDir"
exec 1 | tee "$backupDir/$(basename $0).log"
exec 2 | tee "$backupDir/$(basename $0).log"

backupLast="_backup/last"
echo "make backup to $backupDir"

################################################################################
# functions
updateCouchdbDump() {
    mkdir -p bin
    curl https://raw.githubusercontent.com/danielebailo/couchdb-dump/master/couchdb-backup.sh > bin/couchdb-backup.sh
    chmod +x bin/couchdb-backup.sh
}

backupDB() {
    db=$1

    cmd="bash ${DIR}/bin/couchdb-backup.sh -b -H $host -d $db -f $db.json"
    if [ $user ];then
        cmd="$cmd -u $user"
        if [ $password ];then
            cmd="$cmd -p $password"
        fi
    fi
    $cmd
}

backupAllDBs() {
    pushd $backupDir
    for db in "sw360db" \
              "sw360attachments" \
              "sw360fossologykeys" \
              "sw360users" \
              "sw360vm"; do
        backupDB $db && {
            sha256sum "$db.json" > "$db.json.sha256"
            md5sum "$db.json" > "$db.json.md5"
            du "$db.json" > "$db.json.size"
        } || {
            echo "ERROR: $db backup failed"
            if [ -f "$db.json" ]; then
                mkdir -p failed
                mv "$db.json" failed
            fi
        }
    done
    popd
}

################################################################################
# do the backup

updateCouchdbDump
backupAllDBs
rm $backupLast || true
ln -s $DIR/$backupDir $backupLast
