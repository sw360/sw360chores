#!/usr/bin/env bash
# Copyright Bosch Software Innovations GmbH, 2018.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

set -e

read -p "This will overwrite the current certificates, are you sure? " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

cd "$(dirname $0)"

nginx_key='nginx.key'
nginx_cert='nginx.pem'
password_file='nginx.fifo'

openssl req \
        -newkey rsa:2048 \
        -nodes \
        -keyout "$nginx_key" \
        -x509 \
        -days 365 \
        -out "$nginx_cert" \
        -passout "file:$password_file" \
        -subj '/CN=sw360.localdomain'
