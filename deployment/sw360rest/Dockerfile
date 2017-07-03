# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

FROM sw360baseimage
MAINTAINER admin@sw360.org

RUN . /usr/local/bin/setupProxy.sh && set -x \
 && echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list \
 && $_update && $_install openjdk-8-jre openjdk-8-jdk git-core \
 && apt-get update --fix-missing && $_install maven \
 && $_cleanup \
 && update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java \
 && echo "JAVA_HOME=\"/usr/lib/jvm/java-8-openjdk-amd64/jre\"" >> /etc/environment

RUN mkdir -p /sw360rest
WORKDIR /sw360rest
COPY ./datahandler-1.6.0-SNAPSHOT.jar /tmp/
RUN . /usr/local/bin/setupProxy.sh && set -x \
 && mvn install:install-file -Dfile=/tmp/datahandler-1.6.0-SNAPSHOT.jar -DgroupId=org.eclipse.sw360 -DartifactId=datahandler -Dversion=1.6.0-SNAPSHOT -Dpackaging=jar \
 && git clone https://github.com/sw360/sw360rest /sw360rest \
 && sed -i 's/localhost/sw360/g' \
    subprojects/resource-server/src/main/resources/application.yml \
 && ./gradlew build

EXPOSE 8090
EXPOSE 8091
