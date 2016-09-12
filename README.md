This project contains a bunch of scripts and (config-) files which mainly allow
the user to **package** and **deploy** the environment needed to run an SW360
installation.

# About the folder structure
Each subfolder contains its own readme describing explicitly how to use the
corresponding content.

## The folder `packaging/`
This folder contains all the things related to packaging of the modified tomcat,
in which SW360 runs. The packages containing this modified tomcat have the name
*"sw360_dependencies"*.

The project is capable of creating 
- *.tar.gz*,
- *.deb*  and
- *.rpm*
packages.

## The folder `deployment/`
This folder contains all the things needed to setup SW360, together with
cve-search and nginx, on a docker-enabled host.

To run the containers one needs the .tar.gz packages of *"sw360_dependencies"*
which can be generated with the functionality of `packaging/`.

## The folder `miscellaneous/`
This folder contains the important file `test_users_with_passwords_12345.csv`,
which contains example users which can be used in an development or test
setup. All created users have the password `12345`.

Further this contains the following subfolders

- `couchdbPackager/`, which creates a couchDB rpm package for RHEL/CentOS 7
- `cveSearchBox/`, which contains a simple Vagrantfile which starts a standalone
  cve-search server
- `scripts/`, which contain some useful scripts.

None of the things in this folder are directly used by the packaging or
deployment part.
