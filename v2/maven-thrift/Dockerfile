# Copyright (c) Bosch Software Innovations GmbH 2019.
# Part of the SW360 Portal Project.
#
# SPDX-License-Identifier: EPL-1.0
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

FROM maven:3.6.3-jdk-11

ARG sw360_tag

RUN set -x \
 &&  apt-get update && apt-get install -y wget \
 && wget https://raw.githubusercontent.com/eclipse/sw360/$sw360_tag/scripts/install-thrift.sh \
 && chmod +x /install-thrift.sh \
 && ./install-thrift.sh 

FROM maven:3.6.3-jdk-11

RUN apt-get update && apt-get install -y libfl-dev

COPY --from=0 /usr/local/bin/thrift /usr/local/bin/thrift

