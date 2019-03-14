# Copyright Bosch Software Innovations GmbH, 2016 - 2017.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# using the tomcat image grants us support for the Apache Tomcat Native library, which improves the performance
FROM tomcat:9-jre8-alpine
MAINTAINER admin@sw360.org

WORKDIR /opt/sw360
EXPOSE 8080

RUN apk add --update bash openssl fontconfig ttf-dejavu gettext openjdk8 busybox-extras inotify-tools

ADD sw360-liferay-7.2.0-GA1.tar.gz /opt/

COPY tomcatdeploy.sh /usr/local/bin/tomcatdeploy.sh
COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/opt/sw360/tomcat-9.0.17/logs/catalina.out"]
