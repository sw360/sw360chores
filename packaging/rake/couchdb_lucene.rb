# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

namespace :couchdb_lucene do
  COUCHDB_LUCENE_TARBALL_BN="v#{COUCHDB_LUCENE_VERSION}.tar.gz"
  COUCHDB_LUCENE_URL="https://github.com/rnewson/couchdb-lucene/archive/#{COUCHDB_LUCENE_TARBALL_BN}"
  COUCHDB_LUCENE_TARBALL="#{CACHE_DIR}/#{COUCHDB_LUCENE_TARBALL_BN}"
  COUCHDB_LUCENE_TARDIR="#{TMP_DIR}/#{COUCHDB_LUCENE_NAME}-#{COUCHDB_LUCENE_VERSION}"

  WEBAPPS="#{BUILD_DIR}/webapps"

  file COUCHDB_LUCENE_TARBALL do
    wget [COUCHDB_LUCENE_URL]
  end

  task :fetch => [COUCHDB_LUCENE_TARBALL]

  task :clean do
    rm_rf COUCHDB_LUCENE_TARDIR
  end

  task :extract => [:fetch] do
    mkdir_p TMP_DIR
    sh "tar -zxf #{COUCHDB_LUCENE_TARBALL} -C #{TMP_DIR}"
  end

  task :deploy_config => [:extract] do
    deployStaticFiles({"couchdb-lucene/couchdb-lucene.ini" => "#{COUCHDB_LUCENE_TARDIR}/src/main/resources"})
  end

  task :patch => [:extract] do
    cd COUCHDB_LUCENE_TARDIR
    sh "patch -p1 <#{STATIC_DIR}/couchdb-lucene/couchdb-lucene.patch"
    cd ROOT
  end

  task :build => [:extract, :deploy_config, :patch] do
    cd COUCHDB_LUCENE_TARDIR
    sh "mvn clean install war:war"
    cd ROOT
  end

  task :couchdb_lucene => [:build] do
    mkdir_p WEBAPPS
    mv("#{COUCHDB_LUCENE_TARDIR}/target/#{COUCHDB_LUCENE_NAME}-#{COUCHDB_LUCENE_VERSION}.war", WEBAPPS)
  end
end
