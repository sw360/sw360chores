#!/bin/bash

# Copyright Siemens AG, 2019.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# This scripts watches for new files in a directory and copies them in a
# safe way to anothre directory. Safe way means, that the file is moved
# to the destination with a temporary name (suffixed with .tmp) and is
# finally renamed in that destination directory to the original name.
#
# This is to ensure that the Tomcat only starts deploying after the whole
# file has been copied.


set -e

WATCH_DIR="$1"
DEST_DIR="$2"
LOGFILE="$3"

[[ -n "$WATCH_DIR" ]] || { echo "Need directory to watch as first parameter"; exit 1; }
[[ -n "$DEST_DIR" ]] || { echo "Need destination directory as second parameter"; exit 1; }
[[ -n "$LOGFILE" ]] || { echo "Need logfile to create as third parameter"; exit 1; }

exec &> >(tee -a $LOGFILE)

trap terminate EXIT

function terminate() {
    echo "======================="
    echo "Finished watching for events [$EVENTS] in [$WATCH_DIR] on $(date)"
    echo "======================="
}

echo -e "\n========================"
echo "Start watching for events [close_write] in [$WATCH_DIR] on $(date)"
echo "========================"

mkdir -p "$WATCH_DIR"
echo -n "Starting: "
echo inotifywait --quiet --monitor --event close_write --recursive --format '%w%f' "$WATCH_DIR"

IFS=$(echo -en "\n\b")
shopt -s lastpipe
# the close_write event is triggered if a file is copied into the directory and the last bit has been written
inotifywait --quiet --monitor --event close_write --recursive --format '%w%f' "$WATCH_DIR" 2>&1 | while read FILE
do
    # strip path prefix
    FILE_NAME="$(basename $FILE)"

    echo "Found [$FILE_NAME]. Move to webapps folder [$DEST_DIR] now."
    # since the deploy directory is mounted to the outside
    # we make sure to mv to a tmp-file first and do
    # the rename afterwards which is atomic fore sure
    mv "$FILE" "$DEST_DIR/$FILE_NAME.tmp"
    mv "$DEST_DIR/$FILE_NAME.tmp" "$DEST_DIR/$FILE_NAME"
done

