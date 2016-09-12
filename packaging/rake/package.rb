# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

namespace :package do
  def package(format, name, deps)
    fpm = "fpm -f -s dir -v #{TARGET_VERSION} -n #{name}"
    fpm = fpm << " -t #{format}"
    ["web.xml",
     "context.xml",
     "catalina.policy",
     "catalina.properties",
     "tomcat-users.xml",
     "logging.properties",
     "server.xml",
     "Catalina/localhost/ROOT.xml"].each do |conf|
      fpm = fpm << " --config-files #{TARGET_PREFIX}/conf/#{conf}"
    end
    fpm = fpm << " --after-install ../static/postinstall.sh"
    deps.each do |dependency|
      fpm = fpm << " -d #{dependency}"
    end
    Dir.chdir(OUTPUT_DIR) do
      sh fpm << " --prefix #{TARGET_PREFIX} -C #{BUILD_DIR} ."
    end
  end

  desc "create a .deb package of sw360_dependencies"
  task :deb => [:container] do
    deps = ["openjdk-8-jre",
            "postgresql-9.3",
            "couchdb"]
    package("deb", "#{TARGET_NAME}_dependencies", deps)
    mkdir_p OUTPUT_DIR
    mv(Dir.glob("*.deb"), OUTPUT_DIR)
  end

  desc "create a .rpm package of sw360_dependencies"
  task :rpm => [:container] do
    deps = ["java-1.8.0-openjdk",
            "postgresql-server",
            "couchdb"]
    package("rpm", "#{TARGET_NAME}_dependencies", deps)
    mkdir_p OUTPUT_DIR
    mv(Dir.glob("*.rpm"), OUTPUT_DIR)
  end

  desc "create a .tar.gz package of sw360_dependencies"
  task :tar => [:container] do
    mkdir_p OUTPUT_DIR
    transformation = " --transform='s/#{BUILD_DIR[1..-1].gsub('/','\/')}/#{TARGET_NAME.gsub('/','\/')}/g'"
    sh "tar czf #{OUTPUT_DIR}/#{TARGET_NAME}_dependencies.tar.gz #{BUILD_DIR}" << transformation
  end

  task :all => [:deb, :rpm, :tar]
end
desc "create all three supported packages of sw360_dependencies"
task :package => "package:all"
