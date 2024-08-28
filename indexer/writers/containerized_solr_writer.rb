# frozen_string_literal: true

require "traject"
require "traject/solr_json_writer"

$LOAD_PATH.unshift Pathname.new(__dir__).parent.parent + "lib"
require "dromedary/services"

settings do
  provide "solr.url", Dromedary::Services.solr_embedded_auth_url
  provide "solr_writer.commit_on_close", "false"
  provide "solr_writer.thread_pool", 2
  provide "solr_writer.batch_size", 200
  provide "writer_class_name", "Traject::SolrJsonWriter"
end