# Docker Images for SW360 Project

**This is work in progress**

The goal of the content in this folder is to develop a new and more lightweight deployment, where the single components
SW360 consists of are separated from each other. This allows the containers to have a fast startup time and be small.
It also adds more flexible deployment options, e.g. allowing the frontend to be hosted on a different node than the
backend. 

The long term goal is to merge this with the top level deployment.

This folder is not used by the `../sw360chores.pl` script, but it uses parts of the top level folder `../configuration`.

## Installation
To build all images just run `docker-compose build` in the v2 folder.

Alternatively, you can run `docker build .` within any of the folders to build the image manually.

### Proxy options

If you need to build the image behind an HTTP proxy you can set the proxy with:

```
docker-compose build \
 --build-arg http_proxy=http://127.0.0.1:3128 \
 --build-arg https_proxy=http://127.0.0.1:3128
```

Or in case of docker native build:

```
docker build \
 --build-arg http_proxy=http://127.0.0.1:3128 \
 --build-arg https_proxy=http://127.0.0.1:3128 .
```

### Selecting an SW360 revision

When building the images that contain artifacts from SW360 the docker build
clones the [SW360 Git repository](https://github.com/eclipse/sw360) and checks
out a specific revision. The default revision to be used is defined in the
`.env` file. You can override it using a build argument when invoking the 
docker compose build:

```
docker-compose build \
  --build-arg sw360_tag=master 
``` 

### Local images

As an alternative to building images from the SW360 Git repository, you can use
the artifacts from a local checkout, too. This is useful to test changes during
development immediately. To make this possible, the `v2` folder contains the
`build_local_images.sh` shell script, which builds all the Docker images that
contain SW360 artifacts against a local checkout. Affected are the images
_sw360/backend_, _sw360/rest_, and _sw360/sw360populated_.

The script expects the path to the folder containing the checkout of the SW360
project as parameter. It then builds the artifacts required for the single
images and invokes the Docker files. The resulting images work in the same way
as the ones built from the repository.

## Starting and stopping

Once all images are built, you can run your local SW360 instance via the
`startUp.sh` script located in the `v2` directory. This script basically does a
`docker-compose up` to start all the images involved. However, it also takes
care about race conditions during startup. So it ensures that the CouchDB
container is up and running before starting the SW360 components that depend on
it. After all containers are up, you can access the SW360 start page at
https://localhost:8443.

To shutdown the instance, just use `docker-compose down`.

## Images

This section gives a short overview over the docker images provided by this
project.

### backend

This image will build all components in the Thrift backend module of SW360 and 
deploy them into a tomcat (9). If the container is started, and the couch db
connection was successful, the thrift API will be available on port 8090. 

### couchdb

A simple couchdb container which has some specific configuration options for 
SW360 regarding the integration with lucene. It is based on an official CouchDB
2 image.

CouchDB 2 requires some manual setup steps to configure whether the instance
should run as a cluster or as single node. The scripts contained in the images
handle these setup steps automatically. They also set credentials for the
database: User name and password are both set to _sw360_. The credentials can
be configured in the files `COUCHDB_USER` and `COUCHDB_PASSWORD` in the
`configuration` folder.
 
### couchdb-lucene

A container for the [couchdb-lucene](https://github.com/rnewson/couchdb-lucene) 
project. It provides extended search functionality on data stored in CouchDB. 

### maven-thrift

A maven container which has added Thrift support. This container is also used
to build all SW360 application containers. 

### liferay-base

An image providing the [Liferay](https://www.liferay.com) portal server used by
SW360. During build, the image downloads a recent version of Liferay bundled 
with Tomcat and prepares it for the integration of the SW360 frontend 
components.

### liferay-360

This image sits on top of the _liferay-base_ image. It builds the SW360 
frontend components from the revision selected and adds the resulting artifacts
to the pre-configured Liferay-Tomcat deployment.
