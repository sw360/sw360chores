# Copyright Bosch Software Innovations GmbH, 2017.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

FROM sw360/maven-thrift

RUN apt-get update && apt-get install -y git zip

ARG sw360_tag
ARG GIT_REPOSITORY=https://github.com/eclipse/sw360.git
RUN git clone ${GIT_REPOSITORY}
RUN cd sw360 && git checkout ${sw360_tag}

#Workaround for MVN_PROXY
ARG MVN_FLAGS="-Dhttp.proxyHost=$(basename $http_proxy | cut -d':' -f1) -Dhttp.proxyPort=$(basename $http_proxy | cut -d':' -f2) -Dhttps.proxyHost=$(basename $http_proxy | cut -d':' -f1) -Dhttps.proxyPort=$(basename $http_proxy | cut -d':' -f2) -Dhttp.nonProxyHosts=localhost"   
RUN cd sw360 && \
    mvn $(eval echo "${MVN_FLAGS}" ) install -P deploy -Dbase.deploy.dir=/sw360chores -DskipTests \
    -pl '!rest,!rest/rest-common,!rest/authorization-server,!rest/resource-server,!frontend,!frontend/sw360-portlet,!frontend/liferay-theme,!libraries/importers'
 
WORKDIR /sw360chores/tomcat

COPY create-slim-war-files.sh create-slim-war-files.sh
RUN bash create-slim-war-files.sh

FROM tomcat:9-jdk11
RUN apt-get update && apt-get install -y gettext patch  && rm -rf /var/lib/apt/lists/*

# TOMCAT SETTINGS
COPY catalina.properties.patch /usr/local/tomcat/conf/catalina.properties.patch 
RUN cd /usr/local/tomcat/conf/ && patch -b < catalina.properties.patch
RUN sed -i -e 's/<Engine/<Engine startStopThreads="0" /g' -e 's/<Host/<Host startStopThreads="0" /g' /usr/local/tomcat/conf/server.xml
COPY  --from=0 /sw360chores/tomcat/slim-wars/*.war /usr/local/tomcat/webapps/
COPY  --from=0 /sw360chores/tomcat/libs/*.jar /usr/local/tomcat/shared/

# COUCH DB SETTINGS
ENV COUCHDB_URL="http://172.17.0.1:5984"
ENV COUCHDB_USER=""
ENV COUCHDB_PASSWORD=""
ENV COUCHDB_DBNAME_SW360="sw360db"
ENV COUCHDB_DBNAME_USERDB="sw360users"
ENV COUCHDB_DBNAME_ATTACHMENTS="sw360attachments"
ENV COUCHDB_DBNAME_FOSSOLOGYKEYS="sw360fossologykeys"
ENV COUCHDB_DBNAME_VULNERABILITY_MANAGEMENT="sw360vm"
COPY couchdb.properties.template /etc/sw360/couchdb.properties.template
COPY entrypoint.sh entrypoint.sh
CMD ["bash","entrypoint.sh"]