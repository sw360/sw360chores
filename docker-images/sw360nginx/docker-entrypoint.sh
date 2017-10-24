#!/bin/bash

# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# parsed environmental variables
#    HOST (e.g. sw360)
#    HOST_PORT (e.g. 8080)
#    TARGET_PORT (e.g. 8443)
#    CLIENT_MAX_BODY_SIZE (defaults to "1000m")
#    NGINX_CERTIFICATE
#    KEY_KEY_PRIV_PASSPHRASE
#    NGINX_KEY_PRIV

set -e

client_max_body_size=${CLIENT_MAX_BODY_SIZE:-1000m}

################################################################################
# Setup for custom user-specified certificates
if [ "$NGINX_CERTIFICATE" ] && [ "$NGINX_KEY_PRIV" ]; then
    echo -e "$NGINX_CERTIFICATE" > /etc/nginx/certs/nginx.pem
    echo -e "$NGINX_KEY_PRIV" > /etc/nginx/certs/nginx.key

    if [ "$NGINX_KEY_PRIV_PASSPHRASE" ]; then
        echo "$NGINX_KEY_PRIV_PASSPHRASE" > /etc/nginx/certs/fifo
    fi
fi

################################################################################
## generate /etc/nginx/conf.d/nginx-sw360.conf
cat <<EOF > "/etc/nginx/conf.d/nginx-${HOST}.conf"
upstream ${HOST}-app {
    server ${HOST}:${HOST_PORT} max_fails=3;
}
server {
    listen 8443 ssl default_server;
    listen [::]:8443 ssl default_server;

    # Note: You should disable gzip for SSL traffic.
    # See: https://bugs.debian.org/773332
    #
    # Read up on ssl_ciphers to ensure a secure configuration.
    # See: https://bugs.debian.org/765782
    ssl_certificate /etc/nginx/certs/nginx.pem;
    ssl_certificate_key /etc/nginx/certs/nginx.key;
    ssl_password_file /etc/nginx/certs/fifo;

    root /var/www/html;

    # Add index.php to the list if you are using PHP
    index index.html index.htm index.nginx-debian.html;

    server_name ${HOST}.localdomain;

    location ~* ^/(${RESTRICTED_URLS})/ {
        deny all;
    }

    location / {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_redirect off;
        proxy_pass  http://${HOST}-app;
        proxy_read_timeout 3600s;
    }

    location ~*  \.(jpg|jpeg|png|gif|ico|css|js)$ {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header expires 7d;
        proxy_redirect off;
        proxy_pass  http://${HOST}-app;
        proxy_read_timeout 3600s;
    }
}
EOF

################################################################################
## monify /etc/nginx/nginx.conf
if ! grep -q 'client_max_body_size' /etc/nginx/nginx.conf ; then
    sed -i '$i \
    client_max_body_size '"$client_max_body_size"';' /etc/nginx/nginx.conf
else
    sed -i 's/client_max_body_size .*/client_max_body_size '"$client_max_body_size"';/g' \
        /etc/nginx/nginx.conf
fi

################################################################################
exec "$@"
