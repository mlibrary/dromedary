# frozen_string_literal: true

require "canister"
require "date"
module Dromedary
  Services = Canister.new
  Services.register(:root_directory) { Pathname(__dir__).parent.realdirpath }
  Services.register(:data_directory) { ENV["DATA_DIRECTORY"] || (Services[:root_directory] + "data").to_s }
  Services.register(:build_root) { ENV["BUILD_ROOT"] || "#{Services[:data_directory]}/build" }
  Services.register(:build_directory) do
    default = begin
      yyyymmdd = Date.today.strftime("%Y%m%d")
      default_build_dir = "build_#{yyyymmdd}"
      "#{Services[:build_root]}/#{default_build_dir}"
    end
    ENV["BUILD_DIRECTORY"] || default
  end

  Services.register(:relative_url_root) { "/" }

  Services.register(:solr_root) { ENV["SOLR_ROOT"].chomp("/") || "http://solr/solr" }
  Services.register(:solr_collection) { ENV["SOLR_COLLECTION"] || "dromedary" }

  Services.register(:solr_url) do
    if ENV["SOLR_URL"]
      ENV["SOLR_URL"]
    elsif Services[:solr_root] and Services[:solr_collection]
      Services[:solr_root] + "/" + Services[:solr_collection]
    else
      raise "SOLR_ROOT/SOLR_COLLECTION not defined, nor is SOLR_URL"
    end
  end

  Services.register(:logger) { Rails.logger }

  Services.register(:secret_key_base) { ENV["SECRET_KEY_BASE"] || "somesecretkey" }
end
