# frozen_string_literal: true

require "med_installer/indexing_steps"

module SolrIntegration
  module TestIndex
    ALIAS = "med-spec"
    ARCHIVE = Rails.root.join("spec/fixtures/solr/MED_A_SMALL_SANITIZED.zip")
    REQUIRED_DOCUMENT_IDS = %w[MED100 MED199 BIB628].freeze
    REQUIRED_TEXT_QUERIES = %w[definition_text:lorem quote_text:lorem].freeze
    EXPECTED_MED_ENTRY_COUNT = 131

    def self.ensure_indexed!
      raise "Missing Solr test archive: #{ARCHIVE}" unless ARCHIVE.file?

      return if ready?(new_connection)

      puts "Indexing #{ARCHIVE.basename} into Solr alias #{ALIAS}"
      MedInstaller::IndexingSteps.new(
        zipfile: ARCHIVE.to_s,
        connection: new_connection
      ).index

      raise "Solr alias #{ALIAS} is missing or incomplete after indexing" unless ready?(new_connection)
    end

    def self.ready?(connection)
      return false unless connection.has_alias?(ALIAS)

      collection = connection.get_alias(ALIAS).collection
      return false unless REQUIRED_DOCUMENT_IDS.all? { |id| num_found(collection, "id:#{id}").positive? }
      return false unless REQUIRED_TEXT_QUERIES.all? { |query| num_found(collection, query).positive? }

      num_found(collection, "id:MED*") == EXPECTED_MED_ENTRY_COUNT
    end

    def self.num_found(collection, query)
      response = collection.get("solr/#{collection.name}/select", q: query, defType: "lucene", rows: 0).body
      response.dig("response", "numFound").to_i
    end

    def self.new_connection
      SolrCloud::Connection.new(
        url: Dromedary::Services[:solr_root],
        user: Dromedary::Services[:solr_username],
        password: Dromedary::Services[:solr_password],
        logger: :off
      )
    end
  end
end

if ENV["RUN_INTEGRATION"] == "1"
  RSpec.configure do |config|
    config.before(:suite) { SolrIntegration::TestIndex.ensure_indexed! }
  end
end
