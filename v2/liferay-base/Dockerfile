# Copyright Bosch Software Innovations GmbH, 2016 - 2017.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# using the tomcat image grants us support for the Apache Tomcat Native library, which improves the performance

FROM debian

RUN apt-get update && apt-get install -y curl unzip

COPY portal-bundle.properties portal-bundle.properties
COPY setenv.sh setenv.sh
COPY prepare-liferay.sh prepare-liferay.sh 

RUN bash prepare-liferay.sh
RUN tar -xf sw360-liferay.tar.gz -C /opt/


FROM tomcat:9-jdk11

RUN apt-get update && apt-get install -y \
  bash \
  fontconfig \
  gettext \
  openssl \
  ttf-dejavu

ENV CATALINA_HOME /opt/sw360/tomcat
ENV TOMCAT_NATIVE_LIBDIR $CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR

COPY --from=0 /opt/sw360 /opt/sw360
COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh
COPY deploy.sh /usr/local/bin/deploy.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
 && chmod +x /usr/local/bin/deploy.sh 
RUN cp -r /usr/local/tomcat/native-jni-lib $TOMCAT_NATIVE_LIBDIR \
 && echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> /opt/sw360/tomcat/bin/setenv.sh \
 && echo "export LD_LIBRARY_PATH" >> /opt/sw360/tomcat/bin/setenv.sh
COPY sw360.template.properties /sw360.template.properties

#VOLUME [ "/opt/sw360" ]
EXPOSE 8080

WORKDIR /opt/sw360
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/opt/sw360/tomcat/logs/catalina.out"]
