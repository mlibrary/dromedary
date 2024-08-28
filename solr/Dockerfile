FROM solr:8.11.2

ENV SOLR_AUTH_TYPE="basic"
ENV SOLR_AUTHENTICATION_OPTS="-Dbasicauth=solr:SolrRocks"
ENV SOLR_OPTS="-Denable.packages=true"

RUN mkdir /var/solr/data/lib
RUN chown solr:solr /var/solr/data/lib
COPY --chown=solr:solr lib/*.jar /var/solr/data/lib/
COPY --chown=solr:solr container/security.json /var/solr/data/security.json
COPY --chown=solr:solr container/solr_init.sh /usr/bin/solr_init.sh

ENTRYPOINT ["/usr/bin/solr_init.sh"]

