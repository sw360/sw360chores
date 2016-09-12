# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

namespace :liferay do
  LIFERAY_WAR_FILE="#{LIFERAY_NAME}-#{LIFERAY_VERSION}-ce-ga#{LIFERAY_VERSION_GA}-#{LIFERAY_FILE_POSTFIX}.war"
  LIFERAY_DEPENDENCIES="#{LIFERAY_NAME}-dependencies-#{LIFERAY_VERSION}-ce-ga#{LIFERAY_VERSION_GA}"
  LIFERAY_DEPENDENCIES_FILE="#{LIFERAY_DEPENDENCIES}-#{LIFERAY_FILE_POSTFIX}.zip"
  LIFERAY_SRC="#{LIFERAY_NAME}-src-#{LIFERAY_VERSION}-ce-ga#{LIFERAY_VERSION_GA}"
  LIFERAY_SRC_FILE="#{LIFERAY_SRC}-#{LIFERAY_FILE_POSTFIX}.zip"

  LIFERAY_URL_BASE="http://downloads.sourceforge.net/project/lportal/Liferay%20Portal/#{LIFERAY_VERSION_FULL}%20GA#{LIFERAY_VERSION_GA}"
  LIFERAY_WAR_URL="#{LIFERAY_URL_BASE}/#{LIFERAY_WAR_FILE}"
  LIFERAY_DEPENDENCIES_URL="#{LIFERAY_URL_BASE}/#{LIFERAY_DEPENDENCIES_FILE}"
  LIFERAY_SRC_URL="#{LIFERAY_URL_BASE}/#{LIFERAY_SRC_FILE}"

  POSTGRESQL_JAR_FILE="postgresql-#{POSTGRESQL_JAR_VERSION}.jar"
  POSTGRESQL_JAR_URL="https://jdbc.postgresql.org/download/#{POSTGRESQL_JAR_FILE}"

  ################################################################################
  LIFERAY_TARGET="#{BUILD_DIR}/webapps/ROOT"

  task :clean do
    rm_rf "#{TMP_DIR}/#{LIFERAY_DEPENDENCIES}"
    rm_rf "#{TMP_DIR}/#{LIFERAY_SRC}"
  end

  file "#{CACHE_DIR}/#{LIFERAY_WAR_FILE}" do
    wget [LIFERAY_WAR_URL]
  end

  task :extract => ["#{CACHE_DIR}/#{LIFERAY_WAR_FILE}"] do
    rm_rf LIFERAY_TARGET
    mkdir_p LIFERAY_TARGET
    sh "unzip -q -o #{CACHE_DIR}/#{LIFERAY_WAR_FILE} -d #{LIFERAY_TARGET}"
  end

  file "#{CACHE_DIR}/#{LIFERAY_DEPENDENCIES_FILE}" do
    wget [LIFERAY_DEPENDENCIES_URL]
  end

  file "#{TMP_DIR}/#{LIFERAY_DEPENDENCIES}" => ["#{CACHE_DIR}/#{LIFERAY_DEPENDENCIES_FILE}"] do
    mkdir_p TMP_DIR
    sh "unzip -q -o #{CACHE_DIR}/#{LIFERAY_DEPENDENCIES_FILE} -d #{TMP_DIR}"
  end

  file "#{CACHE_DIR}/#{LIFERAY_SRC_FILE}" do
    wget [LIFERAY_SRC_URL]
  end

  file "#{TMP_DIR}/#{LIFERAY_SRC}" => ["#{CACHE_DIR}/#{LIFERAY_SRC_FILE}"] do
    mkdir_p TMP_DIR
    sh "unzip -q -o #{CACHE_DIR}/#{LIFERAY_SRC_FILE} -d #{TMP_DIR}"
  end

  task "#{CACHE_DIR}/#{POSTGRESQL_JAR_FILE}" do
    wget [POSTGRESQL_JAR_URL]
  end

  task :deploy_dependencies => ["#{TMP_DIR}/#{LIFERAY_DEPENDENCIES}",
                                "#{TMP_DIR}/#{LIFERAY_SRC}",
                                "#{CACHE_DIR}/#{POSTGRESQL_JAR_FILE}"] do
    mkdir_p "#{BUILD_DIR}/lib/ext"
    cp(Dir.glob("#{TMP_DIR}/liferay-portal-dependencies-#{LIFERAY_VERSION}-ce-ga#{LIFERAY_VERSION_GA}/*.jar"), "#{BUILD_DIR}/lib/ext")

    ["development/activation.jar",
     "development/jms.jar",
     "development/jta.jar",
     "development/jutf7.jar",
     "development/mail.jar",
     "development/persistence.jar",
     "portal/ccpp.jar"].each do |dep|
      cp("#{TMP_DIR}/liferay-portal-src-#{LIFERAY_VERSION}-ce-ga#{LIFERAY_VERSION_GA}/lib/#{dep}", "#{BUILD_DIR}/lib/ext")
    end

    mkdir_p "#{BUILD_DIR}/temp/liferay/com/liferay/portal/deploy/dependencies"
    ["resin.jar",
     "script-10.jar"].each do |dep|
      cp("#{TMP_DIR}/liferay-portal-src-#{LIFERAY_VERSION}-ce-ga#{LIFERAY_VERSION_GA}/lib/development/#{dep}",
         "#{BUILD_DIR}/temp/liferay/com/liferay/portal/deploy/dependencies")
    end

    cp("#{CACHE_DIR}/#{POSTGRESQL_JAR_FILE}", "#{BUILD_DIR}/lib/ext")
  end

  task :deploy_config do
    # Configuration of the server (default admin name/password, portal settings, ...)
    deployStaticFiles({"liferay/portal-ext.properties" => "#{LIFERAY_TARGET}/WEB-INF/classes"})
    # Correct liferay's web.xml to avoid security warnings
    ["GET",
     "POST"].each do |method|
      sh "sed -i 's/<http-method>#{method}<\\/http-method>/<!-- \\0 -->/' '#{LIFERAY_TARGET}/WEB-INF/web.xml'"
    end
  end

  task :liferay => [:extract, :deploy_dependencies, :deploy_config]

  task :fetch => ["#{CACHE_DIR}/#{LIFERAY_WAR_FILE}",
                  "#{CACHE_DIR}/#{LIFERAY_DEPENDENCIES_FILE}",
                  "#{CACHE_DIR}/#{LIFERAY_SRC_FILE}",
                  "#{CACHE_DIR}/#{POSTGRESQL_JAR_FILE}"]
end
