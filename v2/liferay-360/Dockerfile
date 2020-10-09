# Copyright Bosch.IO GmbH 2020.
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
    mvn $(eval echo "${MVN_FLAGS}" ) package -P deploy -Dbase.deploy.dir=/sw360chores -DskipTests \
      -pl 'frontend/sw360-portlet,frontend/liferay-theme,libraries/log4j-osgi-support' -am

FROM sw360/sw360empty

COPY  --from=0 /sw360chores/* /sw360chores/
