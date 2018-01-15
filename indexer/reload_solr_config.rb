require 'simple_solr_client'
require 'yaml'
require 'pathname'

require 'awesome_print'
require 'erb'
config_dir = Pathname(__dir__).realdirpath.parent + 'config'
blacklight_yaml = config_dir + 'blacklight.yml'
blacklight_config = YAML.load(ERB.new(File.read(blacklight_yaml)).result)


solr_url  = ENV['SOLR_URL'] || blacklight_config['production']['url']

client = SimpleSolrClient::Client.new(solr_url)
med    = client.core('med')
med.reload
