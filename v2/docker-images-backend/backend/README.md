# thrift based backend
This container contains the thrift http api  

## Files
### catalina.properties.patch
patch which mainly contains a list of dependenies which was manully created by combining all *.war files of the backend. 

### create-slim-war-files.sh
A script that unpacks all wars and repackes them without lib folders. All libs are collected in one shared lib folder.

### couchdb.template.properties
a couchdb.properties file where all values will be replaced with envorinment variables on startup of the container

