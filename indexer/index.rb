$:.unshift "./lib"
require 'nokogiri'
require 'simple_solr_client'
require 'dromedary/entry'
require 'yell'

logger = Yell.new(STDERR)

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
  logger.error "Cannot find file #{path_to_marshal}; exiting"
  exit(1)
end

solr_url = ENV['SOLR_URL'] || 'http://localhost:8983/solr'

client = SimpleSolrClient::Client.new(solr_url)
med    = client.core('med')

unless med.up?
  logger.error "Can't find solr core #{med.name} at #{solr_url}: #{med.ping}"
end


# Do we have individual entries?
individual_entries = ARGV[1..-1]


logger.info "Sucking in entries from all_entries.marshal"
entries = Marshal.load(File.open(path_to_marshal, 'rb'))

if individual_entries.empty?
  logger.info "Clearing out solr"
  med.clear.commit
end

logger.info "Reload core, in case the config changed"
med.reload

if !individual_entries.empty?
  logger.info "Adding #{individual_entries.count} entries"
  to_index = individual_entries.map{|x| entries[x]}
  to_index.each do |e|
    med.add_docs e.solr_doc
  end
  med.commit
  exit(0)
end

logger.info "Beginning indexing of #{entries.count} entries"
i = 1
slice = 2500
entries.each_slice(slice) do |e|
  logger.info "#{(i - 1) * slice} to #{i * slice}"
  i += 1
  begin
    med.add_docs e.map(&:solr_doc)
  rescue => err
    logger.warn "Problem with batch; trying documents one at a time"
    e.each do |doc|
      begin
        med.add_docs(doc.solr_doc)
      rescue => err2
        logger.warn "Problem is with #{doc.id}: #{err2.message} #{err2.backtrace}"
      end
    end
  end
end

med.commit

