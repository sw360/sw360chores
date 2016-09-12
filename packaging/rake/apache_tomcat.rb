# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

namespace :apache_tomcat do
  TOMCAT_TARBALL_BN="#{TOMCAT_NAME}-#{TOMCAT_VERSION}.tar.gz"
  TOMCAT_URL="http://archive.apache.org/dist/tomcat/tomcat-#{TOMCAT_VERSION[0,1]}/v#{TOMCAT_VERSION}/bin/#{TOMCAT_TARBALL_BN}"
  TOMCAT_TARBALL="#{CACHE_DIR}/#{TOMCAT_TARBALL_BN}"

  file TOMCAT_TARBALL do
    wget [TOMCAT_URL]
  end

  task :fetch => [TOMCAT_TARBALL]

  task :extract => [:fetch] do
    mkdir_p BUILD_DIR
    sh "tar -zxf #{TOMCAT_TARBALL} -C #{BUILD_DIR} --strip 1"
  end

  task :disable_caching do
    # caching in tomcat 8 and liferay do not work well together
    if TOMCAT_VERSION[0,1] == "8"
        sh "sed -i 's/^<\\/Context>/    <Resources cachingAllowed=\"false\"\\/>\\n&/' #{BUILD_DIR}/conf/context.xml"
    end
  end

  task :deploy_config => [:extract, :disable_caching] do
    deployStaticFiles({"apache-tomcat/ROOT.xml"         => "#{BUILD_DIR}/conf/Catalina/localhost", # Configuration ROOT.xml that allows multiple web apps to use
                       "apache-tomcat/server.xml"       => "#{BUILD_DIR}/conf", # Setting the ports on which the backend will run, and setting dependencies
                       "apache-tomcat/setenv.sh"        => "#{BUILD_DIR}/bin"}) # default environment to use

    # make ext libraries visible
    key = "common.loader"
    wantedValue = "${catalina.base}/lib,${catalina.base}/lib/*.jar,${catalina.home}/lib,${catalina.home}/lib/*.jar,${catalina.home}/lib/ext,${catalina.home}/lib/ext/*.jar"
    sh "sed -i 's/#{key}=.*/#{key}=#{wantedValue.gsub('/','\/')}/g' #{BUILD_DIR}/conf/catalina.properties"
  end

  task :apache_tomcat => [:extract, :deploy_config]
end
