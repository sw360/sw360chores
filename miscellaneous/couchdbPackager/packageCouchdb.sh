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

TARGET=couchdb
VERSION="1.6.1-2"

rm -rf "./$TARGET" && git clone "https://github.com/wendall911/${TARGET}-rpm" $TARGET

# SPEC="$TARGET/$TARGET.spec"
# spectool -g -R -C "./$TARGET" $SPEC

# sudo mock -r $PLATFORM --buildsrpm --sources "./$TARGET" --spec $SPEC
# cp "/var/lib/mock/$PLATFORM/result/${TARGET}-${VERSION}.$INFIX.src.rpm" $OUT

# sudo mock -r $PLATFORM --installdeps "$OUT/${TARGET}-${VERSION}.$INFIX.src.rpm"

# sudo mock -r $PLATFORM rebuild "$OUT/${TARGET}-${VERSION}.$INFIX.src.rpm"
# cp "/var/lib/mock/$PLATFORM/result/${TARGET}-${VERSION}.$INFIX.x86_64.rpm" $OUT

# sudo mock -r $PLATFORM --install "$OUT/${TARGET}-${VERSION}.$INFIX.x86_64.rpm"


sudo yum groupinstall -y "Development Tools"
sudo yum install -y perl-Test-Harness erlang-erts erlang-os_mon erlang-eunit libicu-devel autoconf-archive curl-devel erlang-etap erlang-asn1 erlang-xmerl js-devel

rm -rf ~/rpmbuild
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros

cp -r ~/$TARGET/* ~/rpmbuild/SOURCES
SPEC=~/rpmbuild/SOURCES/$TARGET.spec
spectool -g -R $SPEC
rpmbuild -bs $SPEC
cp ~/rpmbuild/SRPMS/* $SOUT

sudo yum-builddep -y ~/rpmbuild/SRPMS/${TARGET}-${VERSION}.$INFIX.src.rpm
rpmbuild --rebuild ~/rpmbuild/SRPMS/${TARGET}-${VERSION}.$INFIX.src.rpm
cp ~/rpmbuild/RPMS/x86_64/* $OUT
