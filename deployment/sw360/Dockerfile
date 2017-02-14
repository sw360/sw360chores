# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

FROM java:openjdk-8-jre-alpine
MAINTAINER admin@sw360.org

RUN apk add --update bash

EXPOSE 8080
EXPOSE 5005

COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh
ADD sw360_dependencies.tar.gz /opt
RUN  rm -rf /opt/sw360/webapps/examples \
            /opt/sw360/webapps/docs \
            /opt/sw360/webapps/host-manager \
            /opt/sw360/webapps/couchdb-lucene*war \
            /opt/sw360/RELEASE-NOTES \
            /opt/sw360/RUNNING.txt \
            /opt/sw360/bin/*.bat \
            /opt/sw360/bin/*.tar.gz

VOLUME [ "/opt/sw360" ]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/opt/sw360/logs/catalina.out"]
