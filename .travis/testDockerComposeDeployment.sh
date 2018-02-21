#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Copyright Siemens AG, 2017.
# Copyright Bosch Software Innovations GmbH, 2017.
# Part of the SW360 Portal Project.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved. This file is offered as-is,
# without any warranty.
# -----------------------------------------------------------------------------
set -e

################################################################################
# env

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

################################################################################
# helper functions:

testUrlHttpCode () {
    url="$1"
    set -x
    http_code=$(curl -k -s -o /dev/null -I -w "%{http_code}" "$url")
    [ "$http_code" -lt "400" ]
    set +x
}

testUrlWithSearchString () {
    url="$1"
    needle="$2"
    testUrlHttpCode $url
    set -x
    curl -S -k "$url" | grep -iq "$needle"
    set +x
}

################################################################################
# asserts:

assertTomcat () {
    echo "assert that tomcat running (by examining the log)"
    set -x
    $DIR/sw360chores.pl -- logs sw360 2>/dev/null | grep -iq "Loading file:/opt/portal-bundle.properties"
    $DIR/sw360chores.pl -- logs sw360 2>/dev/null | grep -iq "Determine dialect for PostgreSQL"
    $DIR/sw360chores.pl -- logs sw360 2>/dev/null | grep -iq "org.apache.catalina.startup.Catalina start"
    $DIR/sw360chores.pl -- logs sw360 2>/dev/null | grep -i "INFO: Server startup in"
    set +x
}

assertLiferayViaNginx () {
    echo "assert that Liferay answers over HTTPS via nginx"
    testUrlWithSearchString "https://localhost:8443" "<title>Welcome - SW360</title>"
}

assertLiferayViaHTTP () {
    echo "assert that Liferay answers over HTTP"
    testUrlWithSearchString "http://localhost:8080" "<title>Welcome - SW360</title>"
}

assertCouchdb () {
    echo "assert that CouchDB running (by examining the log)"
    set -x
    $DIR/sw360chores.pl -- logs sw360couchdb 2>/dev/null | grep -iq "Apache CouchDB has started"
    set +x
}

assertCouchdbViaHTTP () {
    echo "assert that CouchDB answers over HTTP"
    testUrlWithSearchString "http://localhost:5984" "\"couchdb\":\"Welcome\""
    testUrlWithSearchString "http://localhost:5984/_utils/" "<title>Overview</title>"
}

assertNoTomcatDebugPort () {
    echo "assert that the tomcat debug port is not open on the host"
    set -x
    ! nc -vz localhost 5005
    set +x
}

################################################################################
# run

## Tomcat
assertTomcat
# if [ "$DEV_MODE" == "true" ]; then
#     assertLiferayViaHTTP
# fi
assertLiferayViaNginx
# if [ "$DEV_MODE" != "true" ]; then
#     assertNoTomcatDebugPort
# fi

## Couchdb
assertCouchdb
# if [ "$DEV_MODE" == "true" ]; then
#     assertCouchdbViaHTTP
# fi
