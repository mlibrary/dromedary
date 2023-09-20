ARG ARCH=amd64
FROM --platform=linux/${ARCH} solr:8-slim

COPY ./lib/*.jar /var/solr/um_plugins/
USER root
# We're going to try actually uploading the configuration files as a .zip
# file using the solr configuration API
#RUN mkdir /opt/solr/server/my_config_sets
#COPY ./med       /opt/solr/server/my_config_sets/med
#RUN apt-get update -yqq && \
#    apt-get install -yqq --no-install-recommends \
#    zip
RUN chown -R solr /opt/solr/
USER solr


#COPY ./dromedary /opt/solr/server/solr/configsets/dromedary
