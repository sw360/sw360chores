#!/bin/sh
# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# this script does
#   - unset the proxies, if they were set to "None"
#   - set the proxies to "${gateway}:3128", if they were set to CNTLM_ON_GATEWAY

if [ "$http_proxy" ]; then
    if [ "$http_proxy" = "None" ]; then
        unset http_proxy
    elif [ "$http_proxy" = "CNTLM_ON_GATEWAY" ]; then
        export "http_proxy"="http://$(ip route get 8.8.8.8 | awk '{ print $3 }'):3128"
    fi
    echo "http_proxy is set to $http_proxy"
fi

if [ "$https_proxy" ]; then
    if [ "$https_proxy" = "None" ]; then
        unset https_proxy
    elif [ "$https_proxy" = "CNTLM_ON_GATEWAY" ]; then
        export "https_proxy"="https://$(ip route get 8.8.8.8 | awk '{ print $3 }'):3128"
    fi
    echo "https_proxy is set to $https_proxy"
fi
