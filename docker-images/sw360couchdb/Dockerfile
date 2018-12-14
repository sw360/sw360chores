# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

FROM couchdb:1.7.1
MAINTAINER admin@sw360.org

RUN mkdir /initial-data

COPY docker-entrypoint.overlay.sh /docker-entrypoint.overlay.sh
run chmod +x /docker-entrypoint.overlay.sh \
 && mkdir -p /usr/local/etc/couchdb/
ENTRYPOINT ["tini", "--", "/docker-entrypoint.overlay.sh"]
CMD ["couchdb"]
