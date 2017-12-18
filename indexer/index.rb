$:.unshift "./lib"
require 'nokogiri'
require 'simple_solr_client'
require 'dromedary/entry'

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


entries.each do |e|
  begin
    med.add_docs e.solr_doc
  rescue => err
      e.logger.warn "Can't index #{e.id}: #{err.message} #{err.backtrace}"
  end
end

med.commit

