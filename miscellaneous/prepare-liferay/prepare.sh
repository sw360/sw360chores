#!/usr/bin/env bash

# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

set -e
cd "$(dirname "${BASH_SOURCE[0]}" )"
DIR="$(pwd)"
TARGET="sw360-liferay-7.2.0-GA1.tar.gz"
LIFERAY="liferay-ce-portal-tomcat-7.2.0-ga1-20190531153709761.tar.gz"
LIFERAY_CHECKSUM="e68ab5dae19063924ae8d7e7ea0078fa"

function downloadModule {
    URL="$1"
    FILE=$(basename $URL)

    echo -n -e "\t$FILE..."

    if [ ! -f "$FILE" ]; then
        curl -OsLC - "$URL"
        echo "OK"
    else
        echo "SKIP"
    fi
}

if [[ $1 == "--cleanup" ]]; then
    if [ -f "$TARGET" ]; then
        rm "$TARGET"
    fi
    exit 0
fi

if [ ! -f "$TARGET" ]; then
    cd downloads

    if [ ! -f "$LIFERAY" ]; then
        echo "... start downloading $LIFERAY (this can take some time)"
        curl -OsLC - 'https://downloads.sourceforge.net/project/lportal/Liferay%20Portal/7.2.0%20GA1/'"$LIFERAY"
    else
        echo "... the file $LIFERAY already exists and does not need to be downloaded again"
    fi

    LIFERAY_ACTUAL_CHECKSUM=$(md5sum $LIFERAY | cut -f 1 -d ' ')
    if [[ "$LIFERAY_ACTUAL_CHECKSUM" != "$LIFERAY_CHECKSUM" ]]; then
        echo $LIFERAY_ACTUAL_CHECKSUM
        echo "the checksum of $DIR/$LIFERAY does not match"
        echo "the file might be corrput, please remove it and restart $0"
        exit 1
    fi

    echo "...start downloading 3rd party dependencies"
    mkdir -p modules
    cd modules

    downloadModule "https://search.maven.org/remotecontent?filepath=commons-codec/commons-codec/1.12/commons-codec-1.12.jar"
    downloadModule "https://search.maven.org/remotecontent?filepath=org/apache/commons/commons-collections4/4.1/commons-collections4-4.1.jar"
    downloadModule "https://search.maven.org/remotecontent?filepath=org/apache/commons/commons-csv/1.4/commons-csv-1.4.jar"
    downloadModule "https://search.maven.org/remotecontent?filepath=commons-io/commons-io/2.6/commons-io-2.6.jar"
    downloadModule "https://search.maven.org/remotecontent?filepath=commons-lang/commons-lang/2.4/commons-lang-2.4.jar"
    downloadModule "https://search.maven.org/remotecontent?filepath=commons-logging/commons-logging/1.2/commons-logging-1.2.jar"
    downloadModule "https://search.maven.org/remotecontent?filepath=com/google/code/gson/gson/2.8.5/gson-2.8.5.jar"
    downloadModule "https://search.maven.org/remotecontent?filepath=com/google/guava/guava/21.0/guava-21.0.jar"
    downloadModule "https://search.maven.org/remotecontent?filepath=com/fasterxml/jackson/core/jackson-annotations/2.9.8/jackson-annotations-2.9.8.jar"
    downloadModule "https://search.maven.org/remotecontent?filepath=com/fasterxml/jackson/core/jackson-core/2.9.8/jackson-core-2.9.8.jar"
    downloadModule "https://search.maven.org/remotecontent?filepath=com/fasterxml/jackson/core/jackson-databind/2.9.8/jackson-databind-2.9.8.jar"

    cd ../..

    echo "... start building $TARGET"

    TMP="$(mktemp -d ${TMPDIR:-/tmp}/tmp.XXXXXXX)"
    tar -xzf "downloads/$LIFERAY" -C "$TMP"
    cp downloads/modules/* "$TMP"/liferay*/osgi/modules/
    cd "$TMP"
    mv liferay* sw360

    # cleanup
    rm -r "$TMP"/sw360/tomcat-*/RELEASE-NOTES \
          "$TMP"/sw360/tomcat-*/RUNNING.txt \
          "$TMP"/sw360/tomcat-*/bin/*.bat \
          "$TMP"/sw360/tomcat-*/bin/*.tar.gz || true

    # configure
    cp "$DIR/portal-bundle.properties" "$TMP/sw360/portal-bundle.properties"
    cp "$DIR/setenv.sh" "$TMP"/sw360/tomcat-*/bin/setenv.sh
    chmod +x "$TMP"/sw360/tomcat-*/bin/setenv.sh

    # pack
    tar czf "$DIR/$TARGET" sw360

    rm -r "$TMP"
else
    echo "... the file $TARGET already exists: skip"
fi

