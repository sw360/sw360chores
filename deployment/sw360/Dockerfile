# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# using the tomcat image grants us support for the Apache Tomcat Native library, which improves the performance
FROM tomcat:8.5.14-jre8-alpine
MAINTAINER admin@sw360.org

RUN apk add --update bash openssl fontconfig ttf-dejavu

WORKDIR /opt/sw360
ENV CATALINA_HOME /opt/sw360
ENV PATH $CATALINA_HOME/bin:$PATH
ENV TOMCAT_NATIVE_LIBDIR $CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR

ADD sw360_dependencies.tar.gz /opt
RUN set -x \
 && mkdir -p /usr/lib/jvm/default-jvm/lib/security/ \
 && rm -rf $CATALINA_HOME/webapps/examples \
            $CATALINA_HOME/webapps/docs \
            $CATALINA_HOME/webapps/manager \
            $CATALINA_HOME/webapps/host-manager \
            $CATALINA_HOME/webapps/couchdb-lucene*war \
            $CATALINA_HOME/RELEASE-NOTES \
            $CATALINA_HOME/RUNNING.txt \
            $CATALINA_HOME/bin/*.bat \
            $CATALINA_HOME/bin/*.tar.gz

VOLUME [ "/opt/sw360" ]

EXPOSE 8080
EXPOSE 5005

COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/opt/sw360/logs/catalina.out"]
