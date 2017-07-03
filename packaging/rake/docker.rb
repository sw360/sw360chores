# Copyright Bosch Software Innovations GmbH, 2016.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

namespace :docker do
  DEV_CONTAINER_NAME = "sw360packager"

  desc "build the docker container needed for the dockerized commands"
  task :build do
    cmd = "cat #{DEV_CONTAINER_NAME}.Dockerfile"
    sh cmd << " | docker build -t sw360/#{DEV_CONTAINER_NAME} --rm=true --force-rm=true -"
  end

  def runInDocker(cmd)
    volume="-v #{ROOT}:/sw360chore"
    volume << " -v #{OUTPUT_DIR}:/sw360chore/_output"
    workdir="-w /sw360chore"
    chroot="chroot --userspec=$(id -u):$(id -g) --skip-chdir /"
    sh "docker run -i #{volume} #{workdir} sw360/#{DEV_CONTAINER_NAME} #{chroot} #{cmd}"
  end

  desc "build the container and predeploy the wars in it"
  task :container do
    runInDocker "rake container"
  end

  namespace :package do
    task :deb => [:container] do
      runInDocker "rake package:deb"
    end

    task :rpm => [:container] do
      runInDocker "rake package:rpm"
    end

    task :tar => [:container] do
      runInDocker "rake package:tar"
    end
  end
  desc "create all three supported packages of sw360_dependencies using a docker container"
  task :package do
    runInDocker "rake package:all"
  end
end
