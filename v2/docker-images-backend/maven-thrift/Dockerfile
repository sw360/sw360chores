# Copyright (c) Bosch Software Innovations GmbH 2019.
# Part of the SW360 Portal Project.
#
# SPDX-License-Identifier: EPL-1.0
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

FROM maven:3.5.0-jdk-8-alpine

RUN set -x \
 &&  apk --update add su-exec git wget \
 && wget https://raw.githubusercontent.com/eclipse/sw360/4a1f90c2a436ed2334d414511cdee6c157a55aec/scripts/install-thrift.sh \
 && chmod +x /install-thrift.sh \
 && ./install-thrift.sh 

FROM maven:3.5.0-jdk-8-alpine

COPY --from=0 /usr/local/bin/thrift /usr/local/bin/thrift 

