ARG arch=arm64
FROM --platform=linux/${arch} solr:8-slim

#COPY ./solr/med/conf /solr_config
COPY ./lib/*.jar /var/solr/um_plugins/
#RUN ls /var/solr/um_plugins/

#ENTRYPOINT ["docker-entrypoint.sh", "solr-precreate", "dromedary-testing", "/solr_config"]

