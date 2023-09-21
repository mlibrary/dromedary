# frozen_string_literal: true

require "canister"
require "date"
require "uri"

module Dromedary
  Services = Canister.new
  Services.register(:root_directory) { Pathname(__dir__).parent.realdirpath }
  Services.register(:data_root) { ENV["DATA_ROOT"] }
  Services.register(:live_data_dir) { Pathname.new(Services[:data_root]) + "live_data" }
  Services.register(:build_directory) do
    default = begin
      yyyymmdd = Date.today.strftime("%Y%m%d")
      default_build_dir = "build_#{yyyymmdd}"
      "#{Services[:data_root]}/build/#{default_build_dir}"
    end
    ENV["BUILD_DIRECTORY"] || default
  end

  Services.register(:data_directory) { (Pathname.new(Services[:build_directory]) + "xml").to_s }

  Services.register(:relative_url_root) { "/" }

  Services.register(:solr_root) { ENV["SOLR_ROOT"].chomp("/") || "http://solr/solr" }
  Services.register(:solr_collection) { ENV["SOLR_COLLECTION"] || "dromedary" }
  Services.register(:solr_username) { ENV["SOLR_USERNAME"] || "solr" }
  Services.register(:solr_password) { ENV["SOLR_PASSWORD"] || "solr" }

  Services.register(:solr_url) do
    if Services[:solr_root] and Services[:solr_collection]
      Services[:solr_root] + "/" + Services[:solr_collection]
    else
      raise "SOLR_ROOT/SOLR_COLLECTION not defined, nor is SOLR_URL"
    end
  end

  Services.register(:solr_embedded_auth_url) do
    uri = URI(Services[:solr_url])
    uri.user = Services[:solr_username]
    uri.password = Services[:solr_password]
    uri.to_s
  end

  # Services.register(:logger) { Rails.logger }

  Services.register(:secret_key_base) { ENV["SECRET_KEY_BASE"] || "somesecretkey" }
end
