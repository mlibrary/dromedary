require "ettin"
require "pathname"
require_relative "../lib/med_installer/logger"
require_relative "../lib/dromedary/services"
require_relative "../lib/med_installer/hyp_to_bibid"

module Dromedary
  class << self
    def logger
      MedInstaller::Logger::LOGGER
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

    def hyp_to_bibid(collection: Dromedary::Services[:solr_current_collection])
      logger.info "Trying to get hyp_to_bibid for collection #{collection}"
      current_real_collection_name = underlying_real_collection_name(coll: collection)
      logger.info "Real collection name identified as #{current_real_collection_name}"
      if @recorded_real_collection_name != current_real_collection_name
        @hyp_to_bibid = MedInstaller::HypToBibId.get_from_solr(collection: collection)
        @recorded_real_collection_name = current_real_collection_name
        @collection_creation_date = nil
      end
      @hyp_to_bibid

    end

    # @param coll [SolrCloud::Alias]
    def underlying_real_collection_name(coll:  Dromedary::Services[:solr_current_collection])
      return coll.name unless coll.alias?
      underlying_real_collection_name(coll: coll.collection)
    end

    def collection_creation_date(coll:  Dromedary::Services[:solr_current_collection])
      return @collection_creation_date if defined?(@collection_creation_date) && !@collection_creation_date.nil?

      real_collection_name = underlying_real_collection_name(coll: coll)
      @collection_creation_date = compute_collection_creation_date(real_collection_name)
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
      Time.now *m[1..5]
    end
  end

  # eager load
  config
end
