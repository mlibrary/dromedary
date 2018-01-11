#!/bin/env ruby


$:.unshift Pathname(__dir__).realdirpath + "lib"
require 'nokogiri'
require 'simple_solr_client'
require 'dromedary/entry'
require 'yell'


path_to_marshal = ARGV[0]
individual_entries = ARGV[1..-1]

unless path_to_marshal
  $stderr.puts <<~USAGE

    Usage: 
      export SOLR_URL="http://whatever:whateverport" (default: localhost:8983)
      
          ruby indexer.rb <path to all_entries.marshal>
      or  ruby indexer.rb <path to all_entries.marshal> list of MED ids

  USAGE
  exit(1)
end


module Dromedary
  class Indexer

    LOGGER = Yell.new(STDERR)

    attr_reader :individual_entries
    attr_reader :client

    def initialize(path_to_marshal, individual_entries = [])
      solr_url            = ENV['SOLR_URL'] || 'http://localhost:8983/solr'
      @marshal_file_name  = self.validate_path(path_to_marshal)
      @client             = self.get_client(solr_url)
      @individual_entries = individual_entries
    rescue => err
      self.logger.error "#{err.message}:\n#{err.backtrace}"
      exit(1)
    end


    def validate_path(path_to_marshal)
      unless File.exist? path_to_marshal
        raise "Cannot find file #{path_to_marshal}; exiting"
      end
      Pathname(path_to_marshal)
    end

    def get_client(solr_url)
      solr_client = SimpleSolrClient::Client.new(solr_url)
      med         = solr_client.core('med')

      unless med.up?
        raise "Can't find solr core #{med.name} at #{solr_url}: #{med.ping}"
      end
      med
    end

    def ientries?
      !@individual_entries.empty?
    end

    def index
      logger.info "Sucking in entries from marshal file. Takes a minute."
      entries = Marshal.load(File.open(@marshal_file_name, 'rb'))
      clean_out unless ientries?
      reload
      if ientries?
        index_ientries(entries)
      else
        index_all(entries)
      end
      logger.info "Committing..."
      client.commit
      logger.info "Build the suggestions index (may take a bit)"
      client.get('search', {'suggest.buildAll' => 'true'})
      logger.info "Indexing complete"
    end

    def clean_out
      logger.info "Clearing out solr"
      @client.clear.commit
    end

    def reload
      logger.info "Reload core, in case the config changed"
      @client.reload
    end

    def index_ientries(entries)
      logger.info "Adding #{individual_entries.count} entries"
      to_index = individual_entries.map {|x| entries[x]}
      to_index.each do |e|
        client.add_docs e.solr_doc
      end
    end

    def index_all(entries)
      logger.info "Beginning indexing of #{entries.count} entries"
      i     = 1
      slice = 10_000
      entries.each_slice(slice) do |e|
        logger.info "#{(i - 1) * slice} to #{i * slice}"
        i += 1
        begin
          client.add_docs e.map(&:solr_doc)
        rescue => err
          logger.warn "Problem with batch; trying documents one at a time"
          e.each do |doc|
            begin
              client.add_docs(doc.solr_doc)
            rescue => err2
              logger.warn "Problem is with #{doc.id}: #{err2.message} #{err2.backtrace}"
            end
          end
        end
      end
    end

    def logger
      LOGGER
    end

  end
end

indexer = Dromedary::Indexer.new(path_to_marshal, individual_entries)
indexer.index
