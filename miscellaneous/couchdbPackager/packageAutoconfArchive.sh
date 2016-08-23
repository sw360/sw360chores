#!/usr/bin/env bash

# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

TARGET=autoconf-archive
VERSION=2012.09.08-1
SPEC="$TARGET/$TARGET.spec"

rm -rf $TARGET && git clone "https://github.com/wendall911/$TARGET"

spectool -g -R -C "./$TARGET" $SPEC

sudo mock -r $PLATFORM --buildsrpm --sources "./$TARGET" --spec $SPEC
cp "/var/lib/mock/$PLATFORM/result/${TARGET}-${VERSION}.$INFIX.src.rpm" $SOUT

sudo mock -r $PLATFORM --installdeps "$SOUT/${TARGET}-${VERSION}.$INFIX.src.rpm"

sudo mock -r $PLATFORM rebuild "$SOUT/${TARGET}-${VERSION}.$INFIX.src.rpm"
cp "/var/lib/mock/$PLATFORM/result/${TARGET}-${VERSION}.$INFIX.noarch.rpm" $OUT

sudo mock -r $PLATFORM --install "$OUT/${TARGET}-${VERSION}.$INFIX.noarch.rpm"
