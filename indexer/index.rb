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
      or  ruby indexer.rb <path to all_entries.marshal> list of MED ids

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


# Do we have individual entries?
individual_entries = $ARGV[1..-1]


$stderr.puts "Sucking in entries from all_entries.marshal"
entries = Marshal.load(File.open(path_to_marshal, 'rb'))

if individual_entries.empty?
  $stderr.puts "Clearing out solr"
  med.clear.commit
end


$stderr.puts "Reload core, in case something changed"
med.reload

if !individual_entries.empty?
  entries = entries.select{|x| individual_entries.include? x.id }
end

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

