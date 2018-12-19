#!/usr/bin/env bash

# Copyright Bosch Software Innovations GmbH, 2016 - 2017.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# the used / parsed environmental variables are:
#
# for liferay
#    $PORTAL_EXT_PROPERTIES (optional)
#    $PORT (optional)
#
# for postgres configuration
#    $POSTGRES_HOST
#    $POSTGRES_USER
#    $POSTGRES_PASSWORD_FILE
#
# for couchdb configuration
#    $COUCHDB_HOST
#    $COUCHDB_USER (optional)
#    $COUCHDB_PASSWORD_FILE (optional)
#
# for trusting SSL certificates
#    $HTTPS_HOSTS (optional)
#
# for setting up cve-search connection
#    $CVE_SEARCH_HOST (optional)
#
# for configuring ldap importer
#    $LDAP_IMPORTER_CONFIGURATION (optional)
#
# for debugging
#    $TOMCAT_DEBUG_PORT (optional)
#
# to serve the tomcat logs under /logs
#    $SERVE_LOGS
#
# secrets:
#    fossology.id_rsa (the expected file location can be overwritten by $FOSSOLOGY_KEY_LOCATION)
#    fossology.id_rsa.pub (the expected file location can be overwritten by $FOSSOLOGY_PUBKEY_LOCATION)
#    certificates (the expected file location can be overwritten by $CERTIFICATES_FILE_LOCATION)
#
# configs:
#    /sw360.properties
#    /ldapimporter.properties
#    /portal-ext.properties

set -e

################################################################################
# Setup JAVA_OPTS
if [ "$JAVA_OPTS_EXT" ]; then
    cat <<EOF >> /opt/sw360/bin/setenv.sh
JAVA_OPTS="\$JAVA_OPTS $JAVA_OPTS_EXT"
export JAVA_OPTS
EOF
fi

################################################################################
# Setup serving of logs
if [ "$SERVE_LOGS" ]; then
    cat <<EOF > /opt/sw360/conf/Catalina/localhost/logs.xml
<Context override="true" docBase="/opt/sw360/logs/" path="/logs" />
EOF
else
    rm -f /opt/sw360/conf/Catalina/localhost/logs.xml
fi

################################################################################
# setup config files
mkdir -p /etc/sw360/
if [[ -f /sw360.properties ]]; then
    envsubst < /sw360.properties > /etc/sw360/sw360.properties
fi
if [[ -f /ldapimporter.properties ]]; then
    envsubst < /ldapimporter.properties > /etc/sw360/ldapimporter.properties
fi

################################################################################
# Setup liferay ()
EXT_PROPERTIES_FILE=/etc/sw360/portal-ext.properties
if [[ -f /portal-ext.properties ]]; then
    envsubst < /portal-ext.properties > $EXT_PROPERTIES_FILE
fi
if [[ $PORT ]]; then
    echo "web.server.https.port=$PORT" >> $EXT_PROPERTIES_FILE
fi

# Setup postgres for liferay
if [ ! "$POSTGRES_HOST" ] || [ ! "$POSTGRES_USER" ] || ( [ ! -f "$POSTGRES_PASSWORD_FILE" ] && [ ! "$POSTGRES_PASSWORD"] ); then
    echo "postgres configuration incomplete"
    exit 1
fi
if [ -f "$POSTGRES_PASSWORD_FILE" ]; then
    POSTGRES_PASSWORD=$(cat $POSTGRES_PASSWORD_FILE)
fi
cat <<EOF >> $EXT_PROPERTIES_FILE
jdbc.default.driverClassName=org.postgresql.Driver
jdbc.default.url=jdbc:postgresql://${POSTGRES_HOST:-localhost}:5432/sw360pgdb
jdbc.default.username=$POSTGRES_USER
jdbc.default.password=$POSTGRES_PASSWORD
EOF
export DB_TYPE=POSTGRESQL


################################################################################
# Setup couchdb
if [ ! "$COUCHDB_HOST" ]; then
    echo "couchdb configuration incomplete"
    exit 1
fi
echo "couchdb.url = http://${COUCHDB_HOST}:5984" > /etc/sw360/couchdb.properties
if [ "$COUCHDB_USER" ]; then
    echo "couchdb.user = $COUCHDB_USER" >> /etc/sw360/couchdb.properties
fi
if [ -f "$COUCHDB_PASSWORD_FILE" ]; then
    COUCHDB_PASSWORD="$(cat "$COUCHDB_PASSWORD_FILE")"
fi
if [ "$COUCHDB_PASSWORD" ]; then
    echo "couchdb.password = $COUCHDB_PASSWORD" >> /etc/sw360/couchdb.properties
fi
echo >> /etc/sw360/couchdb.properties

################################################################################
# Setup for HTTPS hosts
#
# $HTTPS_HOSTS should be a comma seperated list if `host:port` pairs, e.g.
#    "some.bdp_host.org:443,an.ldaps.host:636"
[[ "$JAVA_HOME" ]] || JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")
if [ "$HTTPS_HOSTS" ]; then
    for HOST in $(echo $HTTPS_HOSTS | sed "s/,/ /g"); do
        echo "Trust certificate of host $HOST ..."
        openssl s_client -connect "${HOST}" < /dev/null \
            | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > public.crt

        keytool -keystore "$JAVA_HOME/lib/security/cacerts" \
                -alias "$HOST" \
                -storepass changeit \
                -noprompt \
                -import -file public.crt || echo "INFO: certificate for host $HOST was not imported"
    done
fi

################################################################################
# Setup for trusted Certificate Authorities
#
# $TRUSTED_CACERTS should be a comma separated list of environment variable
# names, e.g.:
# "TRUSTED_CA1,TRUSTED_CA2"
# Mentioned variables ($TRUSTED_CA1 and $TRUSTED_CA2 in this example) should
# contain the certificates, e.g.:
# -----BEGIN CERTIFICATE-----
# AAAAAAAAAAAAAAAAAAAAAAAAAAAA
# -----END CERTIFICATE-----
if [ "$TRUSTED_CACERTS" ]; then
    for CERT_NAME in $(echo $TRUSTED_CACERTS | sed "s/,/ /g"); do
        if [ "${!CERT_NAME}" ]; then
          echo "Trust certificate $CERT_NAME ..."
          OUT="$(mktemp).crt"
          echo -e "${!CERT_NAME}" > $OUT
          keytool -keystore "$JAVA_HOME/lib/security/cacerts" \
                  -alias "$CERT_NAME" \
                  -storepass changeit \
                  -noprompt \
                  -import -file $OUT || echo "INFO: certificate $CERT_NAME was not imported"
        fi
    done
fi

# Import certificates from certificates shared via docker secrets
# This File can contain multiple certificates, seperated by newline
CERTIFICATES_FILE_LOCATION=${CERTS_DIR:-/run/secrets/certificates}
if [ -f "$CERTIFICATES_FILE_LOCATION" ]; then
    echo "Trust certificates in $CERTIFICATES_FILE_LOCATION ..."
    ( cd $(mktemp -d)
      cat "$CERTIFICATES_FILE_LOCATION" \
          | awk 'split_after==1{c++;split_after=0} /-----END CERTIFICATE-----/ {split_after=1} {print > ("cert_extracted_from_certificates" c ".cer")}'

      shopt -s nullglob
      for CERT in *; do
          keytool -keystore "$JAVA_HOME/lib/security/cacerts" \
                  -alias "$CERT" \
                  -storepass changeit \
                  -noprompt \
                  -import -file $CERT || echo "INFO: certificate $CERT was not imported"
      done
    )
fi

################################################################################
# Setup for cve-search
if [ "$CVE_SEARCH_HOST" ]; then
    echo "cvesearch.host = $CVE_SEARCH_HOST" > /etc/sw360/cvesearch.properties
fi

################################################################################
# Setup for FOSSology
if [ "$FOSSOLOGY_HOST" ] && [ "$FOSSOLOGY_PORT" ]; then
    echo "fossology.host = $FOSSOLOGY_HOST" > /etc/sw360/fossology.properties
    echo "fossology.port = $FOSSOLOGY_PORT" >> /etc/sw360/fossology.properties
    if [ "$FOSSOLOGY_USER" ]; then
        echo "fossology.user = $FOSSOLOGY_USER" >> /etc/sw360/fossology.properties
    fi

    FOSSOLOGY_KEY_LOCATION=${FOSSOLOGY_KEY_LOCATION:-/run/secrets/fossology.id_rsa}
    if [ -f "$FOSSOLOGY_KEY_LOCATION" ]; then
        ln -s "$FOSSOLOGY_KEY_LOCATION" /etc/sw360/fossology.id_rsa
        chmod 600 /etc/sw360/fossology.id_rsa
    fi
    FOSSOLOGY_PUBKEY_LOCATION=${FOSSOLOGY_PUBKEY_LOCATION:-/run/secrets/fossology.id_rsa.pub}
    if [ -f "$FOSSOLOGY_PUBKEY_LOCATION" ]; then
        ln -s "$FOSSOLOGY_PUBKEY_LOCATION" /etc/sw360/fossology.id_rsa.pub
        chmod 600 /etc/sw360/fossology.id_rsa.pub
    fi
fi

################################################################################
# Startup apache
CATALINA_OPTS="-Dorg.ektorp.support.AutoUpdateViewOnChange=true"
if [ "$TOMCAT_DEBUG_PORT" ] && [[ "$TOMCAT_DEBUG_PORT" =~ ^[0-9]+$ ]]; then
    CATALINA_OPTS+=" -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=${TOMCAT_DEBUG_PORT}"
fi
DB_TYPE="$DB_TYPE" CATALINA_OPTS="$CATALINA_OPTS" /opt/sw360/bin/startup.sh

################################################################################
exec "$@"
