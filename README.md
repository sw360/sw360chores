# SW360 chores

This repository contains code which sets up a Docker based deployment and development infrastructure for [SW360](https://github.com/eclipse/sw360).
It simplifies and abstracts the configuration.
It also contains tools for backing up and restoring of container states as well as for exporting and importing docker images.

## Prerequisites
You need
- the perl interpreter to run `./sw360chores.pl`
- `git` which is used in some prepare scripts 
- a current version of docker (min 1.30) [https://docs.docker.com/]
- docker-compose (min 1.21) [https://docs.docker.com/compose/install/]
- some disk space at `/var`:
- Internet connection at container build time to download docker images as well
  as Maven dependencies and internet connection at runtime to allow cve-search to
  crawl various external sources for security vulnerability entries.

## Overview
A full setup together with a dockerized FOSSology on another host could look like this:
![Overview of the topology](./.documentation/sw360container-setup.png)

# Usage

This project should be controlled via the script `sw360chores.pl`.
## Simple and quick startup
To build all images and start them simply use
```
./sw360chores.pl --build -- up
```
To get a fully configured [SW360](https://github.com/eclipse/sw360) running, you need to compile the wars and place them into `./_deploy`.
This can be done from within the SW360 project root with a single command via
```
$ mvn install -P deploy -Ddeploy.dir=/ABSOLUTE/PATH/TO/sw360chores/_deploy -DskipTests
```
After that you should follow the [next steps in the SW360 wiki](https://github.com/eclipse/sw360/wiki#portal-deployment-next-steps).

## Complete script usage description
To get the complete description of how to use the script use
```
./sw360chores.pl --help
```

## Configuration

All configuration is done in the folder `./configuration/`, and the structure looks like:
```
configuration
├── certs
├── configuration.pl
├── COUCHDB_PASSWORD
├── nginx
│   ├── nginx.fifo
│   ├── nginx.key
│   ├── nginx.pem
│   └── regenerateCerts.sh
├── POSTGRES_PASSWORD
├── proxy.env
└── sw360
    ├── sw360.env
    ├── fossology
    │   ├── fossology.id_rsa
    │   └── fossology.id_rsa.pub
    ├── ldapimporter.properties
    ├── portal-ext.properties
    └── sw360.properties
```
**Note:** The content of `./configuration/` is only runtime configuration which is partially used on build time (e.g. `proxy.env` and `configuration.pl`), but should not be persisted in the generated images.

#### The file `./configuration/certificates`
This file should contain the TLS certificates of services the server wants to talk to. This should contain e.g. the companies root certificate.

It should contain the certificates concatenated in one file, separated by a newline.

#### The file `./configuration/configuration.pl`
This contains some configuration for the `sw360chores.pl`.
Most of the flags can also be overwritten via CLI-flags.

#### The file `./configuration/COUCHDB_PASSWORD`
This file just contains the password for CouchDB and it is added as secret to the containers.

To deactivate the authentication on CouchDB and start it in admin party mode, just call
```
$ echo > configuration/COUCHDB_PASSWORD
```
This might be necessary for running the SW360 tests against the exposed database.

#### The folder `./configuration/nginx/`
This folder contains all files necessary for the https termination via nginx.
As default this contains an unsafe key-pair.

There is also the file `./configuration/nginx/regenerateCerts.sh`, which is used for regenerating the unsafe key-pair.

#### The file `./configuration/POSTGRES_PASSWORD`
This file just contains the password for postgres and it is added as secret to the containers.

#### The file `./configuration/proxy.env`
Here one can add proxy settings, which are passed to all docker-compose calls and into the containers, which need to connect to the internet.

#### The folder `./configuration/sw360/`

The file `./configuration/sw360/sw360.env` can be used to tweak some runtime environment variables.

The files `ldapimporter.properties`, `portal-ext.properties` and `sw360.properties` are placed at `/etc/sw360/` in the container and can be used to configure the corresponding parts.
In these files are variables replaced with environment variables.

#### The folder `./configuration/sw360/fossology/**
This folder contains the rsa-key-pair used for the SSH connection to the FOSSology server necessary for the upload to FOSSology functionality.

**Note:** which server to use is configured in `./configuration/sw360/sw360.env`.

### Migration from old `./configuration.yml` to the new `./configuration/` folder

Starting with the old configuration, it should be easy to move all configuration to the corresponding files in `./configuration/`.

# Advanced usage:

#### Logging
For implementing a centralized logging we recomend the
[gliderlabs/logspout](https://github.com/gliderlabs/logspout) container, which
collects and routes the logs of all container in a very configurable way.

Further documentation can be found in the corresponding
[README.md](https://github.com/gliderlabs/logspout/blob/master/README.md).

#### Backup and restore content of docker volumes
The `./sw360chores.pl` command has the optional parameters `--backup` and
`--restore` which allow to write the content of all related volumes to tar
files, which are placed in the folder defined as `BACKUP_FOLDER` in
`./configuration.env`.

#### Backup of postgres sql data
To generate a dump:
```bash
$ docker exec -t sw360postgres pg_dumpall -c -U postgres > dump_`date +%d-%m-%Y"_"%H_%M_%S`.sql
```

#### Using sw360chores together with docker swarm
To deploy the configured deployment to a swarm, one should use the commands
```
$ ./sw360chores.pl --swarm --build --prod [...]
$ docker stack deploy --compose-file <(./sw360chores.pl --prod --swarm -- config) sw360
```
**Note:** This feature is currently supported but might be dropped soon in the future. If you plan to depend on that, please communicate that back to the project.

## Vagrant for testing / demonstration

One can build the docker setup within a Virtualbox controlled by Vagrant via
```
$ vagrant up && vagrant reload
```
It will then consume the content from `./_deploy`.

The log from docker than can be watched via
```
$ vagrant ssh -c "/sw360chores/sw360chores.pl -- logs -f"
```

More description can be found in the file `./Vagrantfile`.

# About the folder structure

## The folder `./configuration/`
This folder was explained above.

## The folder `./docker-images/`
This folder contains the Dockerfiles and scripts to build the images.

## The folder `./deployment/`
This folder contains the docker-compose files, which describe how the images
should be configured.

## The folder `./miscellaneous/`
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

## Folders starting with `_`
All folders starting with `_` are transient.
