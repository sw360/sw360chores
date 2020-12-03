# Copyright Bosch Software Innovations GmbH, 2016 - 2017.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# using the tomcat image grants us support for the Apache Tomcat Native library, which improves the performance
FROM tomcat:9.0.40-jdk11-openjdk-slim
MAINTAINER admin@sw360.org

ENV DEBIAN_FRONTEND noninteractive

WORKDIR /opt/sw360
EXPOSE 8080

RUN apt-get update && apt-get install -y bash openssl fontconfig ttf-dejavu gettext inotify-tools netcat

ADD sw360-liferay-7.3.3-ga4.tar.gz /opt/

COPY tomcatdeploy.sh /usr/local/bin/tomcatdeploy.sh
COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD tail -f /opt/sw360/$TOMCAT/logs/catalina.out
