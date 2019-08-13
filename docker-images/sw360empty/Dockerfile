# Copyright Bosch Software Innovations GmbH, 2016 - 2017.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# using the tomcat image grants us support for the Apache Tomcat Native library, which improves the performance
FROM tomcat:8-jre8-alpine
MAINTAINER admin@sw360.org

RUN apk add --update bash openssl fontconfig ttf-dejavu gettext

ENV CATALINA_HOME /opt/sw360
ENV TOMCAT_NATIVE_LIBDIR $CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR

ADD sw360-liferay.tar.gz /opt/
RUN cp -r /usr/local/tomcat/native-jni-lib $TOMCAT_NATIVE_LIBDIR \
 && echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> /opt/sw360/bin/setenv.sh \
 && echo "export LD_LIBRARY_PATH" >> /opt/sw360/bin/setenv.sh \
 && echo "# The following line adds the folder /etc/sw360/rest/ to the config locations for Spring" >> /opt/sw360/bin/setenv.sh \
 && echo "# This allows to add an application.yml file in the folder which overwrites configuration" >> /opt/sw360/bin/setenv.sh \
 && echo "# This will break with an upgrade to Spring version 2.0" >> /opt/sw360/bin/setenv.sh \
 && echo "# see: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-2.0-Migration-Guide#configuration-location" >> /opt/sw360/bin/setenv.sh \
 && echo "# to migrate one has to do s/location/additional-location/" >> /opt/sw360/bin/setenv.sh \
 && echo "JAVA_OPTS=\"\$JAVA_OPTS -Dspring.config.location=file:/etc/sw360/rest/\"" >> /opt/sw360/bin/setenv.sh

WORKDIR /opt/sw360

EXPOSE 8080

COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/opt/sw360/logs/catalina.out"]
