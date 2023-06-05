ARG ARCH=amd64
FROM --platform=linux/${ARCH} solr:8-slim

COPY ./dromedary /opt/solr/server/solr/configsets/dromedary
COPY ./lib/*.jar /var/solr/um_plugins/
COPY ./med /opt/solr/server/solr/configsets/med
