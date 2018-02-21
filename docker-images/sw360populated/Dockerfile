# Copyright Bosch Software Innovations GmbH, 2017.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

FROM sw360/sw360empty:latest

COPY _deploy/*.war /opt/sw360/deploy/
COPY _webapps/*.war /opt/sw360/webapps/

RUN set -ex \
 && for war in /opt/sw360/webapps/*.war; do \
      folder=${war%.war}; \
      mkdir -p $folder; \
      unzip -q $war -d $folder; \
      rm $war; \
    done
