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
#    SERVE_COUCHDB (defaults to "false")
#    CLIENT_MAX_BODY_SIZE (defaults to "1000m")

serve_couchdb=${SERVE_COUCHDB:-false}
client_max_body_size=${CLIENT_MAX_BODY_SIZE:-1000m}


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

    root /var/www/html;

    # Add index.php to the list if you are using PHP
    index index.html index.htm index.nginx-debian.html;

    server_name ${HOST}.localdomain;

    location / {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
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
