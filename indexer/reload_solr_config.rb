require 'simple_solr_client'
require 'yaml'
require 'pathname'

require 'awesome_print'
require 'erb'
config_dir = Pathname(__dir__).realdirpath.parent + 'config'
blacklight_yaml = config_dir + 'blacklight.yml'
blacklight_config = YAML.load(ERB.new(File.read(blacklight_yaml)).result)

uri  = URI(ENV['SOLR_URL'] || blacklight_config['production']['url'])

puts 'URI is #{uri.to_s}'
path = uri.path.split('/')
corename = path.pop
uri.path = path.join('/') # go up a level -- we popped off the core name
solr_url = uri.to_s

puts "SOLR URL is #{solr_url}"

client = SimpleSolrClient::Client.new(solr_url)
core    = client.core(corename)
core.reload
