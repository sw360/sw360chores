# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html


FROM maven:3.6.3-jdk-11
ENV BRANCH="v2.1.0"
RUN apt-get update && apt-get install -y git
RUN git clone --branch $BRANCH --depth 1 https://github.com/rnewson/couchdb-lucene             

#Workaround for MVN_PROXY
ARG MVN_FLAGS="-Dhttp.proxyHost=$(basename $http_proxy | cut -d':' -f1) -Dhttp.proxyPort=$(basename $http_proxy | cut -d':' -f2) -Dhttps.proxyHost=$(basename $http_proxy | cut -d':' -f1) -Dhttps.proxyPort=$(basename $http_proxy | cut -d':' -f2) -Dhttp.nonProxyHosts=localhost"   
RUN cd couchdb-lucene && mvn $(eval echo "${MVN_FLAGS}" ) 


FROM java:openjdk-8-jre-alpine  

ARG TARGET="couchdb-lucene-2.1.0-dist.zip"
MAINTAINER admin@sw360.org

WORKDIR /
COPY --from=0  /couchdb-lucene/target/${TARGET} /
RUN set -ex \
 && apk add --update unzip \
 && unzip /${TARGET}  \
 && apk del unzip \
 && mv /couchdb-lucene-2.1.0 /couchdb-lucene

EXPOSE 5985
COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh 
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/couchdb-lucene/bin/run"]
