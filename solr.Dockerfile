FROM solr:8-slim

COPY ./solr/med/conf /solr_config
COPY ./solr/lib /var/solr/lib/

ENTRYPOINT ["docker-entrypoint.sh", "solr-precreate", "dromedary-testing", "/solr_config"]

