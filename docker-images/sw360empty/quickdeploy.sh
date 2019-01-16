#!/bin/bash

# Copyright Siemens AG, 2019.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

set -e

WATCH_DIR="$1"
DEST_DIR="$2"
LOGFILE="$3"

[[ -n "$WATCH_DIR" ]] || { echo "Need directory to watch as first parameter"; exit 1; }
[[ -n "$DEST_DIR" ]] || { echo "Need destination directory as second parameter"; exit 1; }
[[ -n "$LOGFILE" ]] || { echo "Need logfile to create as third parameter"; exit 1; }

trap terminate EXIT

function terminate() {
    echo "=======================" | tee -a "$LOGFILE"
    echo "Finished watching for events [$EVENTS] in [$WATCH_DIR] on $(date)" | tee -a "$LOGFILE"
    echo "=======================" | tee -a "$LOGFILE"
}

echo -e "\n========================" | tee -a "$LOGFILE"
echo "Start watching for events [modify,delete] in [$WATCH_DIR] on $(date)" | tee -a "$LOGFILE"
echo "========================" | tee -a "$LOGFILE"

echo -n "Starting: " | tee -a "$LOGFILE"
echo inotifywait --quiet --monitor --event modify --event delete --recursive --format '%w%f' "$WATCH_DIR" | tee -a "$LOGFILE"

IFS=$(echo -en "\n\b")
shopt -s lastpipe
inotifywait --quiet --monitor --event modify --event delete --recursive --format '%w%f' "$WATCH_DIR" 2>&1 | tee -a "$LOGFILE" | while read FILE
do
    # strip path prefix
    FILE_NAME="${FILE#"$WATCH_DIR"}"

    # Sometimes we got events for temporary files which disappears before they are copied.
    # Do not fail in these cases
    set +e
    if [ -r "$FILE" ]; then
        echo "Update [$FILE_NAME]" | tee -a "$LOGFILE"
        cp "$FILE" "$DEST_DIR/$FILE_NAME"
    else
        echo "File $FILE_NAME no longer exists. Remove file." | tee -a "$LOGFILE"
        rm -f "$DEST_DIR/$FILE_NAME" | tee -a "$LOGFILE"
    fi
    set -e

done

