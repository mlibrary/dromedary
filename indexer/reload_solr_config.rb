require 'simple_solr_client'

solr_url = ENV['SOLR_URL'] || 'http://localhost:8983/solr'

client = SimpleSolrClient::Client.new(solr_url)
med    = client.core('med')
med.reload
