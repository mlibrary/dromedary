require "traject/indexer"

module Dromedary
  class QuoteIndexer
    attr_accessor :settings, :indexer, :logger

    def initialize(passed_settings = {})
      index_dir = SolrHelper.index_dir
      default_settings = {
        "log.batch_size" => 2_500,
        "reader_class_name" => "MedInstaller::Traject::EntryJsonReader",
        "solr_writer.batch_size" => 200,

        :writer_file => index_dir + "writers" + "localhost.rb",
        :rule_files => [Pathname(__dir__) + "basic_rules.rb"]
      }
      @settings = default_settings.merge passed_settings
      @logger = AnnoyingUtilities.logger
      create_indexer!(@settings)
    end

    def create_indexer!(settings = self.settings)
      @indexer = Traject::Indexer.new(settings)
      settings[:rule_files].each { |rf|
        logger.info "Loading #{rf}"
        @indexer.load_config_file(rf)
      }
      @indexer.load_config_file(settings[:writer_file])
      @indexer
    end

    def writer
      indexer.writer
    end

    def put(record, position)
      ctxt = Traject::Indexer::Context.new(
        source_record: record,
        settings: settings,
        position: position,
        logger: logger
      )
      indexer.map_to_context!(ctxt) # side-effects the context
      writer.put(ctxt)
    end
  end
end
