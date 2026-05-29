FROM solr:10.0.0

ENV SOLR_AUTH_TYPE="basic"
ENV SOLR_AUTHENTICATION_OPTS="-Dbasicauth=solr:SolrRocks"
ENV SOLR_OPTS="-Denable.packages=true"
# Enables ICUTokenizerFactory, ICUFoldingFilterFactory, ICUNormalizer2CharFilterFactory
ENV SOLR_MODULES="analysis-extras"

COPY --chown=solr:solr container/security.json /var/solr/data/security.json
COPY --chown=solr:solr container/solr_init.sh /usr/bin/solr_init.sh

ENTRYPOINT ["/usr/bin/solr_init.sh"]
