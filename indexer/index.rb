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

solr_url = ENV['SOLR_URL'] || 'http://localhost:8983/solr'

client = SimpleSolrClient::Client.new(solr_url)
med = client.core('med')

unless med.up?
  $stderr.puts "Can't ping #{med.name}: #{med.ping}"
end

$stderr.puts "Getting entries"
entries = Marshal.load(File.open(path_to_marshal, 'rb'))

$stderr.puts "Beginning indexing"
entries.each do |e|
  begin
    med.add_docs e.solr_doc
  rescue => err
      e.logger.warn "Can't index #{e.id}: #{err.message} #{err.backtrace}"
  end
end

med.commit

