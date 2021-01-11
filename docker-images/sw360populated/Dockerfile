# Copyright Bosch Software Innovations GmbH, 2017.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

FROM sw360/sw360empty:latest

COPY _deploy/tomcat/* /opt/sw360/deploy/tomcat/
COPY _deploy/liferay/* /opt/sw360/deploy/liferay/

RUN apt-get update && apt-get install -y unzip

RUN set -ex \
 && for war in /opt/sw360/deploy/tomcat/*.war; do \
      folder=$(basename $war .war); \
      (cd /opt/sw360/tomcat-*; \
       mkdir -p webapps/$folder; \
       unzip -q $war -d webapps/$folder); \
      rm $war; \
    done
