#!/bin/bash

# Copyright Bosch Software Innovations GmbH, 2019.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

set -e 

rm -rf libs
mkdir libs
rm -rf slim-wars
mkdir slim-wars
for i in $(ls *.war)
do
  i=${i%.war}
  echo repacking $i ...
  rm -rf $i 
  mkdir $i 
  cd $i && unzip -q ../$i.war
  mv WEB-INF/lib/* ../libs/
  rmdir WEB-INF/lib
  zip -q -r ../slim-wars/$i.war .
  cd ..
  rm -rf $i
  echo done
done
