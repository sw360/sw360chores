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

TARGET=js185
SPEC="$TARGET/js.spec"
VERSION=1.8.5-15

rm -rf $TARGET && git clone "https://github.com/wendall911/$TARGET"
# OR: https://github.com/meltwater/autoconf-archive-rpm

spectool -g -R -C "./$TARGET" $SPEC

sudo mock -r $PLATFORM --buildsrpm --sources "./$TARGET" --spec $SPEC
cp "/var/lib/mock/$PLATFORM/result/js-${VERSION}.$INFIX.src.rpm" $SOUT

sudo mock -r $PLATFORM --installdeps "$SOUT/js-${VERSION}.$INFIX.src.rpm"

sudo mock -r $PLATFORM rebuild "$SOUT/js-${VERSION}.$INFIX.src.rpm"
cp "/var/lib/mock/$PLATFORM/result/js-devel-${VERSION}.$INFIX.x86_64.rpm" $OUT
cp "/var/lib/mock/$PLATFORM/result/js-debuginfo-${VERSION}.$INFIX.x86_64.rpm" $OUT
cp "/var/lib/mock/$PLATFORM/result/js-${VERSION}.$INFIX.x86_64.rpm" $OUT

sudo mock -r $PLATFORM --install "$OUT/js-${VERSION}.$INFIX.x86_64.rpm"
sudo mock -r $PLATFORM --install "$OUT/js-devel-${VERSION}.$INFIX.x86_64.rpm"
