#!/usr/bin/env bash
# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
JAVA_OPTS="$JAVA_OPTS -Dfile.encoding=UTF8"
JAVA_OPTS="$JAVA_OPTS -Dorg.apache.catalina.loader.WebappClassLoader.ENABLE_CLEAR_REFERENCES=false"
JAVA_OPTS="$JAVA_OPTS -Duser.timezone=GMT"
JAVA_OPTS="$JAVA_OPTS -Xms2g -Xmx4g"
JAVA_OPTS="$JAVA_OPTS -XX:+UseParNewGC"
JAVA_OPTS="$JAVA_OPTS -XX:+UseConcMarkSweepGC"
JAVA_OPTS="$JAVA_OPTS -XX:+CMSParallelRemarkEnabled"
JAVA_OPTS="$JAVA_OPTS -XX:SurvivorRatio=20"

export JAVA_OPTS
