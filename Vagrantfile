# -*- mode: ruby -*-
# vi: set ft=ruby :

# Copyright Bosch Software Innovations GmbH, 2016 - 2017.
# Part of the SW360 Portal Project.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# Usage:
#   prepare VM by building it
#       using: $ vagrant up
#   run docker-compose inside of the VM by booting a built VM
#       using: $ vagrant reload
#          or: $ vagrant up` after `vagrant halt
#
# to view the log run
#   $ vagrant ssh -c "/sw360chores/sw360chores.pl -- logs -f"
#
# This is meant to be a testing environment. It should not be used in productive environments
#
# by default this stets the development settings

Vagrant.configure(2) do |config|
  config.vm.box = "debian/stretch64"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 6000
    vb.cpus = 3
  end

  config.vm.synced_folder ".", "/vagrant",
                          disabled: true

  config.vm.provision "shell", inline: <<-SHELL
set -xe
apt install -y curl git
type docker &> /dev/null || \
    curl -sSL https://get.docker.com/ | sh
usermod -a -G docker vagrant
type docker-compose &> /dev/null || \
    curl -L https://github.com/docker/compose/releases/download/1.8.0/docker-compose-`uname -s`-`uname -m` > /usr/bin/docker-compose 2> /dev/null
chmod +x /usr/bin/docker-compose
SHELL

  if File.exists?(File.join(File.dirname(__FILE__),".vagrant/machines/default/virtualbox/action_provision"))
    excludesArray=[]
    File.open ".gitignore" do |f|
        f.each_line {|line|
          excludesArray.push line.gsub(/\n?/, "")
        }
    end
    config.vm.synced_folder ".", "/sw360chores",
                            type: "rsync",
                            rsync__exclude: excludesArray

    # build and run with docker compose
    config.vm.provision "shell",
                        run: "always",
                        privileged: false,
                        inline: <<-SHELL
set -xe
/sw360chores/sw360chores.pl --build -- up -d

echo "servers are runnnig"
echo "for deployment, place the .war files in ./_deploy"
SHELL

    config.vm.synced_folder "./_deploy", "/sw360chores/_deploy",
                            rsync__auto: "true"

    # tomcat https (via nginx):
    config.vm.network "forwarded_port", guest: 8443, host: 8443
    # tomcat debug port:
    config.vm.network "forwarded_port", guest: 5005, host: 5005
    # couchdb:
    config.vm.network "forwarded_port", guest: 5984, host: 5984
    # # postgres:
    # config.vm.network "forwarded_port", guest: 5432, host: 5432
  end
end
