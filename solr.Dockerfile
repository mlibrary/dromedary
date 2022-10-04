FROM solr:8-slim

COPY ./solr/med/conf /solr_config
COPY ./solr/lib/*.jar /var/solr/um_plugins/
#RUN ls /var/solr/um_plugins/

#ENTRYPOINT ["docker-entrypoint.sh", "solr-precreate", "dromedary-testing", "/solr_config"]

