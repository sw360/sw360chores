#!/usr/bin/env bash

# Copyright Bosch.IO 2020
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# This script is a work-around for a problem with the auto-deployment mechanism
# of Liferay: Deployment does not work for artifacts contained in the 
# deployment folder when Liferay starts up. Therefore, this script monitors the
# log file of Tomcat to find out when the server has started, and only then
# copies the artifacts to be deployed from a source directory into the deploy
# folder.

# The following parameters are expected:
# 1 - path to the source folders with files to deploy
# 2 - path to the deploy folder
# 3 - path to the log file to monitor
# 4 - path to the file storing the MD5 checksum of the deployment
# 5 - the MD5 checksum of the new deployment

echo "Deployment of artifacts from $1 to $2."

echo "Waiting for server to start up..."
( tail -f -n0 $3 & ) | grep -q "Server startup"

echo "Server is up. Trigger deployment..."
cp $1/* $2

echo $5 > $4
echo "Updated checksum of current deployment to $5."
