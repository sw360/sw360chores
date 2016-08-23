# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

set -ex

PLATFORM="epel-7-x86_64"
INFIX="el7.centos"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUT=$DIR/RPMS
SOUT=$OUT/SRPMS
mkdir -p $SOUT

cd ~
