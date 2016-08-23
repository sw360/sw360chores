#!/usr/bin/env bash

# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

set -ex

mkdir -p RPMS
cp ../../_output/*.rpm RPMS/
vagrant destroy -f
vagrant up
vagrant ssh -c "sudo /opt/sw360/bin/startup.sh && tailf /opt/sw360/logs/catalina.out"
