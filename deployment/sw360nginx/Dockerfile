# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

FROM nginx

RUN nginx_cert_dir='/etc/nginx/certs' \
    nginx_key='nginx.key' \
    nginx_cert='nginx.pem' \
    set -x \
 && mkdir -p $nginx_cert_dir \
 && openssl req -newkey rsa:2048 -nodes -keyout "$nginx_cert_dir/$nginx_key" -x509 -days 365 -out "$nginx_cert_dir/$nginx_cert" -subj '/CN=sw360.localdomain'

EXPOSE 8443

COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
