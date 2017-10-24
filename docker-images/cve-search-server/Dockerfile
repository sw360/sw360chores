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

ENV BRANCH=4c165eff1af0e4c7bdf103c341203717ae677f64

ENV _update="apt-get update"
ENV _install="apt-get install -y --no-install-recommends"
ENV _cleanup="eval apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*"

RUN set -x \
 && $_update && $_install git-core python3 python3-dev python3-pip gcc \
        python-anyjson python-argparse python-pymongo \
        libxml2 python-libxml2 libxml2-dev libxslt-dev libxslt1-dev python-dev zlib1g-dev \
 && pip3 install -q -U pip \
 && $_cleanup

run mkdir -p /cve-search
ADD "cve-search@$BRANCH.tar.gz" /cve-search
WORKDIR /cve-search
run set -x \
 && pip install -r requirements.txt \
 && cp etc/configuration.ini.sample etc/configuration.ini \
 && sed -i 's/Host: 127.0.0.1/Host: 0.0.0.0/' etc/configuration.ini

COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 5000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["server"]
