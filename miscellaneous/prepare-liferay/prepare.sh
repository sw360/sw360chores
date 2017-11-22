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
TARGET="sw360-liferay.tar.gz"

if [ ! -f "$TARGET" ]; then
    LIFERAY="liferay-portal-tomcat-6.2-ce-ga5-20151119152357409.zip"
    if [ ! -f "$LIFERAY" ]; then
        curl -OskLC - 'https://downloads.sourceforge.net/project/lportal/Liferay%20Portal/6.2.4%20GA5/liferay-portal-tomcat-6.2-ce-ga5-20151119152357409.zip'
    else
        echo "... the file $LIFERAY already exists: skip"
    fi

    TMP=$(mktemp -d ${TMPDIR:-/tmp}/tmp.XXXXXXX)

    unzip -q $LIFERAY -d $TMP
    cd $TMP
    cp -r liferay*/tomcat* ./sw360
    rm -r liferay*

    # cleanup
    rm -r $TMP/sw360/webapps/{calendar-portlet,docs,examples,host-manager,kaleo-web,manager,notifications-portlet,opensocial-portlet,resources-importer-web,sync-web,web-form-portlet} \
          $TMP/sw360/RELEASE-NOTES \
          $TMP/sw360/RUNNING.txt \
          $TMP/sw360/bin/*.bat \
          $TMP/sw360/bin/*.tar.gz || true

    # configure
    sed -i 's/<http-method>GET<\/http-method>/<!-- \0 -->/' "$TMP/sw360/webapps/ROOT/WEB-INF/web.xml"
    sed -i 's/<http-method>POST<\/http-method>/<!-- \0 -->/' "$TMP/sw360/webapps/ROOT/WEB-INF/web.xml"
    cp $DIR/portal-bundle.properties $TMP/portal-bundle.properties
    cp $DIR/setenv.sh $TMP/sw360/bin/setenv.sh
    chmod +x $TMP/sw360/bin/setenv.sh

    # pack
    tar czf $DIR/$TARGET sw360 portal-bundle.properties

    rm -r $TMP
else
    echo "... the file $TARGET already exists: skip"
fi
