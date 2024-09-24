require "ettin"
require "pathname"
require_relative "../lib/med_installer/logger"
require_relative "../lib/dromedary/services"
require_relative "../lib/med_installer/hyp_to_bibid"
require "ttl_memoizeable"

module Dromedary
  class << self
    extend TTLMemoizeable
    def logger
      Rails.logger || MedInstaller::Logger::LOGGER
    end

    # For whatever historical reasons, this uses the Ettin gem to load
    # up yaml files. The list of places it looks are:
    #         root/"settings.yml",
    #         root/"settings"/"#{env}.yml",
    #         root/"environments"/"#{env}.yml",
    #         root/"settings.local.yml",
    #         root/"settings"/"#{env}.local.yml",
    #         root/"environments"/"#{env}.local.yml"
    def config
      return @config unless @config.nil?
      env = if defined? Rails
        Rails.env
      elsif %w[production development test].include? ENV["RAILS_ENV"]
        ENV["RAILS_ENV"]
      else
        "development"
            end
      @config = Dromedary::Services
    end


    def hyp_to_bibid
      collection = Dromedary::Services[:solr_current_collection]
      Rails.logger.warn "################# Fetching HyperBib ########################"
      MedInstaller::HypToBibId.get_from_solr(collection: collection)
    end

    def collection_creation_date
      Rails.logger.warn "################# Fetching creation date ########################"
      collection = Dromedary::Services[:solr_current_collection]
      if collection
        Dromedary.compute_collection_creation_date collection.collection.name
      else
        "Never"
      end
    end

    ttl_memoized_method :hyp_to_bibid, ttl: 20.seconds
    ttl_memoized_method :collection_creation_date, ttl: 20.seconds

    def collection_creation_date_string
      collection_creation_date.strftime("%A, %B %-e, %Y at %H:%M:%S")
    end

    def compute_collection_creation_date(coll)
      name  = case coll
              when String
                coll
              when SolrCloud::Collection
                coll.name
              else
                raise "Need a collection or its name"
              end
      m = /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})\Z/.match(name)
      Time.new *m[1..5]
    end
  end

  # eager load
  config
end
