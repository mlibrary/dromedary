# frozen_string_literal: true

require "canister"
require "date"
require "uri"

module Dromedary
  Services = Canister.new
  Services.register(:root_directory) { Pathname(__dir__).parent.parent.realdirpath }
  Services.register(:tmp_dir) do
    tmpdir = Services[:root_directory] + "tmp"
    tmpdir.mkpath
    tmpdir
  end

  # The "live data dir" is no longer used for anything but holding onto the
  # maintenance mode flag.

  #### NAMING ####

  Services.register(:production_alias) { ENV["SOLR_PRODUCTION_ALIAS"] || "med-production" }
  Services.register(:preview_alias) {   ENV["SOLR_PREVIEW_ALIAS"]     ||  "med-preview" }

  Services.register(:relative_url_root) { ENV['RAILS_RELATIVE_URL_ROOT'] || '/' }

  Services.register(:allow_admin_access) do
    ["1", 1, "true", "TRUE"].include? ENV["ALLOW_ADMIN_ACCESS"]
  end


  ################ Generic Solr stuff ##################

  # If there's no collection there, and we're in the "allow admin access" case, it might just
  # be the first time we're trying to upload data.

  Services.register(:looks_like_first_upload) do
    if Services[:allow_admin_access] and Services[:solr_current_collection].nil?
      logger = Services[:logger]
      logger.warn "Admin access allowed and collection is nil. Assuming this is the first upload of a new install"
      logger.warn "Otherwise, something went very wrong"
      true
    end
  end


  Services.register(:solr_root) { (ENV["SOLR_ROOT"] || "http://solr:8983/").chomp("/") }
  Services.register(:solr_collection_base) { ENV["SOLR_COLLECTION_BASE"] || "med" }
  Services.register(:solr_collection) { ENV["SOLR_COLLECTION"] }
  Services.register(:solr_username) { ENV["SOLR_USERNAME"] || "solr" }
  Services.register(:solr_password) { ENV["SOLR_PASSWORD"] || "SolrRocks" }

  Services.register(:solr_replication_factor) { (ENV["SOLR_REPLICATION_FACTOR"] || 3).to_i }

  Services.register(:solr_connection) do
    SolrCloud::Connection.new(url: Services[:solr_root],
                              user: Services[:solr_username],
                              password: Services[:solr_password])
  end

  Services.register(:solr_current_collection) do
    c = Services[:solr_connection]
    name = Services[:solr_collection]
    if !(c.has_collection?(name))
      Services[:logger].warn "Collection/Alias #{name} not found. Probably ok for first-time indexing, but a problem otherwise"
    end
    c.get_collection(name)
  end

  Services.register(:solr_url) do
    if Services[:solr_root] and Services[:solr_collection]
      Services[:solr_root] + "/solr/" + Services[:solr_collection]
    else
      raise "Configuration error: Need both SOLR_ROOT/SOLR_COLLECTION to be defined"
    end
  end

  Services.register(:solr_embedded_auth_url) do
    uri = URI(Services[:solr_url])
    uri.user = Services[:solr_username]
    uri.password = Services[:solr_password]
    uri.to_s
  end


  ################ Reindexing stuff ################

  Services.register(:build_root) do
    br = Pathname.new(ENV["BUILD_ROOT"])
    br.mkpath
    br
  end

  Services.register(:build_date_suffix) do
    Time.now.strftime("%Y%m%d%H%M")
  end

  Services.register(:build_directory) do
    default = Services[:build_root] + "build_#{Services[:build_date_suffix]}"
    bd = Pathname.new(ENV["BUILD_DIRECTORY"] || default)
    bd.mkpath
    bd
  end

  Services.register(:build_xml_directory) do
    Services[:build_directory] + "xml"
  end

  Services.register(:bib_all_xml_file) do
    Services[:build_xml_directory] + "bib_all.xml"
  end
  
  # Legacy usage
  Services.register(:xml_directory) { Services["build_xml_directory"] }

  Services.register(:entries_gz_file) do
    Services[:build_directory] +  "entries.json.gz"
  end

  Services.register(:hyp_to_bibid_file) do
    Services[:build_directory] + "hyp_to_bibid.json"
  end

  Services.register(:indexing_rules_directory) do
    Services.root_directory + "indexer"
  end

  Services.register(:entry_indexing_rules) do
    (Services.indexing_rules_directory + "main_indexing_rules.rb").to_s
  end

  Services.register(:bib_indexing_rules) do
    (Services.indexing_rules_directory + "bib_indexing_rules.rb").to_s
  end

  Services.register(:solr_writer) do
    (Services.indexing_rules_directory + "writers" + "containerized_solr_writer.rb").to_s
  end

  Services.register(:name_of_solr_collection_to_index_into) do
    "#{Services.solr_collection_base}_#{Services.build_date_suffix}"
  end

  Services.register(:solr_collection_to_index_into) do
    Services[:solr_connection].get_collection(Services[:name_of_solr_collection_to_index_into])
  end

  Services.register(:solr_conf_directory) do
    ENV["SOLR_CONF_DIRECTORY"] || (Services[:root_directory] + "solr" + "dromedary" + "conf")
  end


  Services.register(:logger) { ::Rails.logger }

  Services.register(:secret_key_base) { ENV["SECRET_KEY_BASE"] || "somesecretkey" }
end
