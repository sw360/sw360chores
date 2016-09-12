This Folder contains scripts which allow creation of packages, which contain the
dependencies for an SW360 installation.
These packages come in three versions

- .tar.gz
- .deb for Ubuntu
- .rpm for RHEL/CentOS 7

All packages are placed in the folder `_output`.

# How to use
The used versions of the components are configured in the file
`build_configuration.rb`.

There are two ways to use the packaging scripts in this folder.

**1)** The first way,
which needs either
- **rake** and **docker** or
- **rake**, **fpm**, **openjdk8** and more (e.g. for *.deb* or *.rpm* packaging)

The controlling tool is rake and one can get a detailed help via
```
rake --describe
```

If one wants to use the second variation which does not involve docker, one has
to pass the environmental variable `DOCKERIZE` to `rake`, i.e. use something
like
```
DOCKERIZE=false rake command
```

**2)** The other way also uses the above mentioned tools but encapsulates all of that
within a single vagrantbox, which produces packages with every reload.
This box can initially be build via the command
```
vagrant up
```
and every new `up` or `reload` lets this box create new packages from the
current sources.

To also issue building SW360 one can pass the environmental variable
`SW360SOURCE` to vagrant, which should contain the path to the position of the
source code. This can look like
```
SW360SOURCE=/path/to/sw360/source vagrant reload
```
Pulling these sources from github is not yet supported

# About the packages
The packages are made in such a way, that they place the modified tomcat at
`/opt/sw360/` (or, in the case of *.tar.gz*, at least support this)
## About the *.tar.gz* package
This is a basic compressed version of the modified and augmented tomcat, which
is created in the folder `_build`.

## About the *.deb* package
This package has openjdk-8-jre, postgresql-9.3 and couchdb as dependencies,
which are, except for openjdk-8-jdk, all found in the repositories of current
Ubuntu versions.

It could for example be installed via
```
sudo add-apt-repository ppa:openjdk-r/ppa
sudo apt-get update
sudo apt-get install -y openjdk-8-jre
sudo update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java

sudo dpkg -i /PATH/TO/sw360-dependencies_*_amd64.deb || sudo apt-get -f -y install
```

One is then able to deploy SW360 via the command:
```
sudo dpkg -i /PATH/TO/sw360*_amd64.deb || sudo apt-get -f -y install
```

## About the *.rpm* package
This package depends on java-1.8.0-openjdk, postgresql-server and couchdb. Here
is couchdb the problem, which is not even found in the EPEL repositories. As a
solution to this problem this project provides the content of the folder
`miscellaneous/couchdbPackager` which contains the mechanisms to create a
couchdb package. Using this one can use the following description to install sw360_dependencies:

```
yum install -y wget
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh epel-release-latest-7.noarch.rpm

sudo yum --nogpgcheck -y localinstall /PATH/TO/couchdb*.rpm
sudo yum --nogpgcheck -y localinstall /PATH/TO/sw360_dependencies*.rpm
```

One is then able to deploy SW360 via the command:
```
sudo yum --nogpgcheck -y localinstall /PATH/TO/sw360*.rpm
```
