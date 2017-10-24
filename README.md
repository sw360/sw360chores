This project contains a bunch of scripts and (config-) files which mainly allow
the user to **package** and **deploy** the environment needed to run an SW360
installation.

# Usage

This project can be controlled via the script `sw360chores.pl`.

## Simple and fast startup
To build all images and start them simply use
```
./sw360chores.pl --build -- up
```

## Complete discreption
To get the complete description of how to use the script use
```
./sw360chores.pl --help
```

# About the folder structure
Each subfolder contains its own readme describing explicitly how to use the
corresponding content.

## The folder `docker-images/`
tbd

## The folder `deployment/`
tbd

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
