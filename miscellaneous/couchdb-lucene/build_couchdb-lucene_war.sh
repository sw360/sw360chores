# Copyright Bosch Software Innovations GmbH, 2016 - 2017.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

set -ex
cd $(dirname $0)

COUCHDB_LUCENE_VERSION="2.1.0"
COUCHDB_LUCENE_TARBALL="v${COUCHDB_LUCENE_VERSION}.tar.gz"
COUCHDB_LUCENE_URL="https://github.com/rnewson/couchdb-lucene/archive/${COUCHDB_LUCENE_TARBALL}"
COUCHDB_LUCENE_SRC="couchdb-lucene-${COUCHDB_LUCENE_VERSION}"

wget -nc $COUCHDB_LUCENE_URL

tar -zxf $COUCHDB_LUCENE_TARBALL
cp couchdb-lucene.ini "${COUCHDB_LUCENE_SRC}/src/main/resources"

cd $COUCHDB_LUCENE_SRC
patch -p1 <../couchdb-lucene.patch
mvn clean install war:war
mv **/*.war ../

cd ..
rm -rf $COUCHDB_LUCENE_SRC $COUCHDB_LUCENE_TARBALL
