require "hanami/cli"
require "pathname"
require "annoying_utilities"
require "solr_helper"
require "med_installer/logger"
require "med_installer/solr"
require "middle_english_dictionary/collection/bib_set"
require "traject"
require "json"

module MedInstaller
  module Index
    class Generic < Hanami::CLI::Command
      include MedInstaller::Logger

      def index_dir
        SolrHelper.index_dir
      end

      def indexing_rules_file
        raise "Set in subclass"
      end

      def select_writer(debug)
        _writer = if debug
          index_dir + "writers" + "debug.rb"
        else
          index_dir + "writers" + "localhost.rb"
        end
      end

      def collection
        SolrHelper.solr_collection
      end

      def index(rulesfile:, datafile:, bibfile:, writer:)
        indexer = ::Traject::Indexer.new
        indexer.settings do
          store "med.data_file", datafile.to_s
          store "bibfile", bibfile
        end

        indexer.load_config_file rulesfile.to_s
        indexer.load_config_file writer.to_s
        exitstatus = indexer.process(File.open("/dev/null"))
        logger.info "Traject running #{rulesfile} exited with status #{exitstatus}"
      end

      def call(debug:)
        raise "Solr at #{SolrHelper.blacklight_solr_url} not up" unless SolrHelper.solr_collection
        writer = select_writer(debug)
        fields = indexing_rules_file
        index(rulesfile: fields, datafile: filename, writer: writer, bibfile: bibfile)
      end

      def commit
        logger.info "Sending commit"
        collection.commit
      end

      def optimize
        logger.info "Optimizing (long!)"
        collection.optimize
      end
    end

    # -----

    class Entries < Generic
      desc "Index entries into solr using the traject configuration in indexer/main_indexing_rules"

      option :debug, type: :boolean, default: false, desc: "Write to debug file?"

      def indexing_rules_file
        index_dir + "main_indexing_rules.rb"
      end

      def call(debug:)
        HypToBibID.new(command_name: "hyp_to_bib_id").call
        raise "Solr at #{SolrHelper.blacklight_solr_url} not up" unless SolrHelper.solr_collection
        writer = select_writer(debug)
        fields = indexing_rules_file
        index(rulesfile: fields, datafile: SolrHelper.entries_path, writer: writer, bibfile: SolrHelper.bibfile_path)
      end
    end

    # ------
    #

    class Bib < Generic
      desc "Index entries into solr using the traject configuration in indexer/bib_indexing_rules"
      option :debug, type: :boolean, default: false, desc: "Write to debug file?"

      def indexing_rules_file
        index_dir + "bib_indexing_rules.rb"
      end

      def call(debug:)
        HypToBibID.new(command_name: "hyp_to_bib_id").call
        raise "Solr at #{SolrHelper.blacklight_solr_url} not up" unless SolrHelper.solr_collection
        writer = select_writer(debug)
        index(rulesfile: index_dir + "bib_indexing_rules.rb",
          datafile:  SolrHelper.bibfile_path,
          writer:    writer,
          bibfile:   SolrHelper.bibfile_path)
        commit
        optimize
        commit
      end
    end

    #------

    class Full < Generic
      desc "Clear and reload solr, index entries and bib, build autosuggest, and optimize"
      option :debug, type: :boolean, default: false, desc: "Write to debug file?"
      option :existing_hyp_to_bibid, type: :boolean, default: false, desc: "Don't create new hyp_to_bibid"

      def call(debug:, existing_hyp_to_bibid:)
        raise "Solr at #{SolrHelper.blacklight_solr_url} not up" unless SolrHelper.solr_collection
        writer = select_writer(debug)

        logger.info "Creating new collection"
        collection.create_new

        HypToBibID.new(command_name: "hyp_to_bib_id").call unless existing_hyp_to_bibid

        logger.info "##### BEGIN ENTRY/QUOTE INDEXING #####"
        index(rulesfile: index_dir + "main_indexing_rules.rb",
          datafile:  SolrHelper.entries_path,
          writer:    writer,
          bibfile:   SolrHelper.bibfile_path)

        logger.info "##### BEGIN BIB INDEXING #####"

        index(rulesfile: index_dir + "bib_indexing_rules.rb",
          datafile:  SolrHelper.bibfile_path,
          writer:    writer,
          bibfile:   SolrHelper.bibfile_path)
        commit
        MedInstaller::Solr.rebuild_suggesters(collection)
        optimize
        commit
        logger.info "TODO: RENAME THE NEW COLLECTION WE CREATED"
      end
    end

    # -----

    class HypToBibID < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Create the mapping from HYP ids (RID) to bib IDs"

      def bibset(filename)
        @bibset ||= MiddleEnglishDictionary::Collection::BibSet.new(filename: filename)
      end

      def hyp_to_bibid
        return @hyp_to_bibid if @hyp_to_bibid
        logger.info "Building hyp_to_bibid mapping"
        @hyp_to_bibid ||= bibset(SolrHelper.bibfile_path).each_with_object({}) do |bib, acc|
          bib.hyps.each do |hyp|
            acc[hyp.delete("\\").upcase] = bib.id # TODO: Take out when backslashes removed from HYP ids
          end
        end
      end

      def write_hyp_to_bib_id
        logger.info "Creating and writing hyp_to_bibid mapping at #{SolrHelper.hyp_to_bibid_path}"
        File.open(SolrHelper.hyp_to_bibid_path, "w:utf-8") do |out|
          out.puts hyp_to_bibid.to_json
        end
      end

      def call(command_name: "HypToBibID")
        logger.info "Creating hyp_to_bibid.json"
        write_hyp_to_bib_id
      end
    end
  end
end
