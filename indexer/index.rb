require_relative 'basics'
require 'nokogiri'
require 'simple_solr_client'

path_to_marshal = ARGV[0]

unless path_to_marshal
  $stderr.puts <<~USAGE
  
  Usage: 
    export SOLR_URL="http://whatever:whateverport" (default: localhost:8983)
    ruby indexer.rb <path to all_entries.marshal>

  USAGE
  exit(1)
end


unless File.exist? path_to_marshal
  $stderr.puts "Cannot find file #{path_to_marshal}; exiting"
  exit(1)
end

solr_url = ENV['SOLR_URL'] || 'http://localhost:8983'

client = SimpleSolrClient::Client.new(solr_url)
med_core = client.core('med')

unless med_core.up?
  $stderr.puts "Can't ping #{med_core.name}: #{med_core.ping}"
end

entries = Marshal.load(File.open(path_to_marshal, 'rb'))

#
# <field name="main_headword" type="me_text" indexed="true" stored="true" multiValued="false"/>
# <field name="headwords" type="me_text" indexed="true" stored="true" multiValued="true"/>
# <field name="definition_xml" type="string" stored="true" docValues="false" />
# <filed name="definitions" type="text" stored="true" multiValued="true"/>
#
