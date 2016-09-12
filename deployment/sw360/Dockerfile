# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

FROM debian:jessie
MAINTAINER admin@sw360.org
ENV DEBIAN_FRONTEND noninteractive

ENV _update="apt-get update"
ENV _install="apt-get install -y --no-install-recommends"
ENV _cleanup="eval apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*"

RUN set -x \
 && echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list \
 && $_update && $_install openjdk-8-jre && $_cleanup \
 && update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java \
 && echo "JAVA_HOME=\"/usr/lib/jvm/java-8-openjdk-amd64/jre\"" >> /etc/environment

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
CMD ["tailf", "-0", "/opt/sw360/logs/catalina.out"]
