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
med    = client.core('med')

unless med.up?
  $stderr.puts "Can't ping #{med.name}: #{med.ping}"
end

$stderr.puts "Getting entries"
entries = Marshal.load(File.open(path_to_marshal, 'rb'))

$stderr.puts "Beginning indexing"
i = 1
entries.each_slice(1000) do |e|
  puts "#{i * 1000}"
  i += 1
  begin
    med.add_docs e.map(&:solr_doc)
  rescue => err
    puts "Problem with batch; trying one at a time"
    e.each do |doc|
      begin
        med.add_docs(doc.solr_doc)
      rescue => err2
        puts "Problem is with #{doc.id}: #{err2.message} #{err2.backtrace}"
      end
    end
  end
end

med.commit

