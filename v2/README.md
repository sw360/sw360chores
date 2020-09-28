# Docker Images for SW360 Project

**This is work in progress**

The goal of the content in this folder is to develop a new and more lightweight deployment, where the SW360 backend is separated from the frontends.
This allows the containers to have a fast startup time and be small.

The long term goal is to merge this with the top level deployment.

This folder is not used by the `../sw360chores.pl` script, but it uses parts of the top level folder `../configuration`.

## Installation
To build all images just run `docker-compose build` in the corresponding directories

alternativly you can run docker build . within any of the folders to build the image manually

### Proxy options

If you need to build the image behind an HTTP proxy you can set the proxy with

 ```
docker-compose build \
 --build-arg http_proxy=http://127.0.0.1:3128 \
 --build-arg https_proxy=http://127.0.0.1:3128

or in case of docker native build

docker build \
 --build-arg http_proxy=http://127.0.0.1:3128 \
 --build-arg https_proxy=http://127.0.0.1:3128 .
 ``` 

## Images

### backend

This image will build all componentes in the backend module of sw360 and deploy them into an tomcat (9). If the container is started and the couch db connection was correct the thrift API will be available on port 8080. 

### couchdb

 A simple couchdb container which has some specific configuration options for sw360 regards the integration with lucene
 
### couchdb-lucene

A container for the couchdb-lucene project 

### maven-thrift

A maven container which has added thrift support. This container is also used to build all sw360 application containers. 

## Testing with the "old" image with the liferay frontend
```
$ ( cd /PATH/TO/SW360; mvn package -DskipTests )
$ find /PATH/TO/SW360/frontend -name '*.war' -exec cp -v {} ../_deploy \;
$ docker-compose -f docker-images-backend/docker-compose.yaml -f docker-images-frontend/docker-compose.yaml up
```
After that SW360 can be accessed on `https://localhost:8443`.
