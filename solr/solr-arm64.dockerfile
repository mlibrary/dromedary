ARG arch=arm64
FROM --platform=linux/${arch} solr:8-slim

COPY ./lib/*.jar /var/solr/um_plugins/
