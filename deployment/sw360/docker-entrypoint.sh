#!/usr/bin/env bash

# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# the used / parsed environmental variables are:
#
# for postgres configuration
#    $POSTGRES_HOST (defaults to: "localhost")
#    $POSTGRES_USER (optional)
#    $POSTGRES_PASSWORD (optional)
#
# for couchdb configuration
#    $COUCHDB_HOST (defaults to: "localhost")
#    $COUCHDB_USER (optional)
#    $COUCHDB_PASSWORD (optional)
#
# for trusting SSL certificates
#    $HTTPS_HOSTS (optional)
#    $JAVA_HOME (defaults to: path where java lies)
#
# for setting up cve-search connection
#    $CVE_SEARCH_HOST (optional)
#
# for sw360 configuration
#    $PROTOCOL (defaults to: "http")
#
# for LDAP configuration
#    $LDAP_HOST (e.g. ldap://10.1.2.100:389)
#    $LDAP_BASE_DN (e.g. ou=Users,o=Example)
#    $LDAP_PRINCIPAL (e.g. cn=LDAP1,ou=Users,o=Example)
#    $LDAP_CREDENTIALS (e.g. Password)

set -e

################################################################################
# Setup postgres
sed -i 's/jdbc.default.url=.*/jdbc.default.url=jdbc:postgresql:\/\/'"${POSTGRES_HOST:-localhost}"':5432\/sw360pgdb/g' \
    /opt/sw360/webapps/ROOT/WEB-INF/classes/portal-ext.properties
if [ "$POSTGRES_USER" ]; then
    sed -i 's/jdbc.default.username=.*/jdbc.default.username='"$POSTGRES_USER"'/g' \
        /opt/sw360/webapps/ROOT/WEB-INF/classes/portal-ext.properties
fi
if [ "$POSTGRES_PASSWORD" ]; then
    sed -i 's/jdbc.default.password=.*/jdbc.default.password='"$POSTGRES_PASSWORD"'/g' \
        /opt/sw360/webapps/ROOT/WEB-INF/classes/portal-ext.properties
fi

################################################################################
# Setup couchdb
mkdir -p /etc/sw360
echo "couchdb.url = http://${COUCHDB_HOST:-localhost}:5984" > /etc/sw360/couchdb.properties
if [ "$COUCHDB_USER" ]; then
    echo "couchdb.user = $COUCHDB_USER" >> /etc/sw360/couchdb.properties
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
if [ "$HTTPS_HOSTS" ]; then
    [[ "$JAVA_HOME" ]] || JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")
    for HOST in $(echo $HTTPS_HOSTS | sed "s/,/ /g"); do
        echo "Trust certificate of host $HOST ..."
        openssl s_client -connect "${HOST}" < /dev/null \
            | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > public.crt

        keytool -keystore "$JAVA_HOME/lib/security/cacerts" \
                -alias "$HOST" \
                -storepass changeit \
                -noprompt \
                -import -file public.crt || continue
    done
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
    if [ "$FOSSOLOGY_KEY_PRIV" ]; then
        echo "$FOSSOLOGY_KEY_PRIV" > /etc/sw360/fossology.id_rsa
        chmod 600 /etc/sw360/fossology.id_rsa
    fi
    if [ "$FOSSOLOGY_KEY_PUB" ]; then
        echo "$FOSSOLOGY_KEY_PUB" > /etc/sw360/fossology.id_rsa.pub
        chmod 600 /etc/sw360/fossology.id_rsa.pub
    fi
fi

################################################################################
# modify portal ext properties
addToPortalExtProperties() {
    if [[ $1 == *"="* ]]; then
        file="/opt/sw360/webapps/ROOT/WEB-INF/classes/portal-ext.properties"
        key="$( cut -d '=' -f 1 <<< "$1" )"
        if grep -q "$key" $file; then
            sed -i -r 's/'"$key"'=.*/'"$(sed -e 's/[\/&]/\\&/g' <<< "$1")"'/g' $file
        else
            echo "$1" >> $file
        fi
    fi
}

# Setup for nginx with https
addToPortalExtProperties "web.server.protocol=${PROTOCOL:-http}"


# Setup for authentification with ldap
if [[ $LDAP_CONFIGURATION ]]; then
    while read -r line; do
        addToPortalExtProperties "$line"
    done <<< "$LDAP_CONFIGURATION"
fi

################################################################################
# Startup apache
CATALINA_OPTS=""
if [ "$TOMCAT_DEBUG_PORT" ] && [[ "$TOMCAT_DEBUG_PORT" =~ ^[0-9]+$ ]]; then
    CATALINA_OPTS+="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=${TOMCAT_DEBUG_PORT} "
    CATALINA_OPTS+="-Dorg.ektorp.support.AutoUpdateViewOnChange=true "
fi
CATALINA_OPTS="$CATALINA_OPTS" /opt/sw360/bin/startup.sh

################################################################################
exec "$@"
