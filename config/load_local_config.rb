require "ettin"
require "pathname"
require_relative "../lib/med_installer/logger"
require_relative "../lib/dromedary/services"
require_relative "../lib/med_installer/hyp_to_bibid"

module Dromedary
  class << self
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
      current_real_collection = underlying_real_collection_name
      if @recorded_real_collection_name != current_real_collection
        @hyp_to_bibid = MedInstaller::HypToBibId.get_from_solr(collection: collection)
        @recorded_real_collection_name = current_real_collection
      end
      @hyp_to_bibid
    end

    # @param coll [SolrCloud::Alias]
    def underlying_real_collection_name(coll:  Dromedary::Services[:solr_current_collection])
      return coll.name unless coll.alias?
      underlying_real_collection_name(coll: coll.collection)
    end
  end

  # eager load
  config
end
