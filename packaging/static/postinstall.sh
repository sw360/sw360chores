#!/usr/bin/env bash

# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

postgresUser=liferay
postgresPass=sw360fossy
tomcatPort=8080
couchdbPort=5984

################################################################################

if [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
    postgresql-setup initdb
    systemctl enable postgresql.service
    systemctl start postgresql.service
else
    service postgresql start
fi

su - postgres -c "psql -l" | grep -q '^ lportal\b'
if [ $? -ne 0 ]; then
    echo "configure postgres..."
    su - postgres -c "psql -c \"CREATE USER $postgresUser WITH PASSWORD '$postgresPass'\""
    su - postgres -c "psql -c \"CREATE DATABASE lportal;\""
    su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE lportal to $postgresUser\""
else
    echo "configure postgres... table already exists, update password of user..."
    su - postgres -c "psql -c \"ALTER ROLE $postgresUser WITH PASSWORD '$postgresPass'\""
fi

PG_HBA=$(su postgres - bash -c "psql -t -P format=unaligned -c 'show hba_file';" 2>/dev/null)
grep -q "lportal" $PG_HBA
if [ $? -ne 0 ]; then
    echo "configure postgres... modify pg_hba.conf..."
    cat <<EOF > $PG_HBA
# the following modifications are due to the installation of sw360:
local lportal liferay              md5
host  lportal liferay 127.0.0.1/32 md5
$(cat $PG_HBA)
EOF
fi

if [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
    systemctl restart postgresql.service
else
    service postgresql restart
fi

################################################################################
if [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
    systemctl enable couchdb.service
    systemctl start couchdb.service
else
    service couchdb start
fi

if [ -f /etc/couchdb/local.ini ];then
    grep -q "^port = 5984\$" /etc/couchdb/local.ini
    if [ $? -ne 0 ]; then
        echo "configure couchdb..."
        sed -i -r 's/;?.*port *=.*/port = '"$couchdbPort"'/' /etc/couchdb/local.ini
        sed -i -r 's/;?.*bind_address *=.*/bind_address = 0.0.0.0/' /etc/couchdb/local.ini
        sed -i -r 's/\[httpd_global_handlers\]/[httpd_global_handlers]\n_fti = {couch_httpd_proxy, handle_proxy_req, <<"http:\/\/127.0.0.1:'"$tomcatPort"'\/couchdb-lucene">>}/' /etc/couchdb/local.ini

        if [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
            systemctl restart couchdb.service
        else
            service couchdb restart
        fi
    else
        echo "couchdb already configured"
    fi
    if [ ! -d /var/run/couchdb ]; then
        mkdir /var/run/couchdb
    fi
fi

################################################################################
grep -q sw360 /etc/group || groupadd sw360
id sw360 >/dev/null 2>&1 || useradd -M -s /bin/nologin -g sw360 -d /opt/sw360 sw360

chgrp -R sw360 /opt/sw360/conf
chmod g+rwx /opt/sw360/conf
chmod g+r /opt/sw360/conf/*

mkdir -p /opt/sw360/{webapps,work,temp,logs,deploy}
chown -R sw360 /opt/sw360/{webapps,work,temp,logs,deploy}

################################################################################
if [ -d /etc/systemd/system ]; then
    cat <<EOF > /etc/systemd/system/sw360.service
# Systemd unit file for sw360
[Unit]
Description=SW360 Portal
After=syslog.target network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/jre
Environment=CATALINA_PID=/opt/sw360/temp/sw360.pid
Environment=CATALINA_HOME=/opt/sw360
Environment=CATALINA_BASE=/opt/sw360
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/sw360/bin/startup.sh
ExecStop=/bin/kill -15 $MAINPID

User=sw360
Group=sw360

[Install]
WantedBy=multi-user.target
EOF
elif [ -d /etc/init/ ]; then
    cat <<EOF > /etc/init/sw360.conf
description "Sw360 Server"

  start on runlevel [2345]
  stop on runlevel [!2345]
  respawn
  respawn limit 10 5

  setuid sw360
  setgid sw360

  env JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
  env CATALINA_HOME=/opt/sw360

  # Modify these options as needed
  env JAVA_OPTS="-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"
  env CATALINA_OPTS="-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

  exec $CATALINA_HOME/bin/catalina.sh run

  # cleanup temp directory after stop
  post-stop script
    rm -rf $CATALINA_HOME/temp/*
  end script
EOF
fi

exit 0
