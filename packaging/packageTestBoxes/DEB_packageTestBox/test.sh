#!/usr/bin/env bash

# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

set -ex

sudo add-apt-repository ppa:openjdk-r/ppa # for openjdk-8-jre
sudo apt-get update
sudo apt-get install -y openjdk-8-jre
sudo update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java

sudo dpkg -i /vagrant/DEBS/sw360-dependencies_*_amd64.deb || sudo apt-get -f -y install
sudo dpkg -i /vagrant/DEBS/sw360_*_amd64.deb || sudo apt-get -f -y install
