require 'hanami/cli'
require 'pathname'
require 'annoying_utilities'
require 'med_installer/logger'
require 'med_installer/solr'
require 'traject'


module MedInstaller
  module Index

    class Generic < Hanami::CLI::Command
      include MedInstaller::Logger
      include AnnoyingUtilities

      def index_dir
        AnnoyingUtilities::DROMEDARY_ROOT + 'indexer'
      end

      def indexing_rules_file
        raise "Set in subclass"
      end

      def select_writer(debug)
        writer = if debug
                   index_dir  + 'writers' + 'debug.rb'
                 else
                   index_dir + 'writers' + 'localhost.rb'
                 end
      end

      def core
        core = AnnoyingUtilities.solr_core
        # Commit with index building can take a looooong time. Set the timeout to 100seconds
        core.rawclient.receive_timeout = 200_000 # 200 seconds
        core
      end

      def index(rulesfile:, datafile:, writer:)
        indexer = ::Traject::Indexer.new
        indexer.settings do
          store 'med.data_file', datafile.to_s
        end
        indexer.load_config_file rulesfile.to_s
        indexer.load_config_file writer.to_s
        indexer.process(File.open('/dev/null'))

        #
        # system "bundle", "exec", "traject",
        #        "-c", rulesfile.to_s,
        #        "-c", writer.to_s,
        #        "-s", "med.data_file=#{datafile}",
        #        "/dev/null", # traject requires a file on command line, no matter what
        #        out: $stdout, err: :out
        logger.info "Traject running #{rulesfile} exited with status #{$?.exitstatus}"
      end

      def call(filename:, debug:)
        raise "Solr at #{AnnoyingUtilities.solr_url} not up" unless AnnoyingUtilities.solr_core.up?
        writer = select_writer(debug)
        fields = indexing_rules_file
        index(rulesfile: fields, datafile: filename, writer: writer)
      end

      def commit
        logger.info "Sending commit"
        core.commit
      end

      def optimize
        logger.info "Optimizing (long!)"
        core.optimize
      end

    end

    class Entries < Generic

      desc "Index entries into solr using the traject configuration in indexer/main_indexing_rules"

      argument :filename, required: true, desc: "The location of entries.json.gz"
      option :debug, type: :boolean, default: false, desc: "Write to debug file?"

      def indexing_rules_file
        index_dir + 'main_indexing_rules.rb'
      end

    end

    class Bib < Generic
      desc "Index entries into solr using the traject configuration in indexer/bib_indexing_rules"

      argument :filename, required: true, desc: "The location of bib_all.xml"
      option :debug, type: :boolean, default: false, desc: "Write to debug file?"

      def indexing_rules_file
        index_dir + 'bib_indexing_rules.rb'
      end
    end

    class Full < Generic
      desc "Clear and reload solr, index entries and bib, build autosuggest, and optimize"
      argument :entries_file, required: true, desc: "Path to entries.json.gz"
      argument :bib_file, required: true, desc: "Path to bib_all.xml"
      option :debug, type: :boolean, default: false, desc: "Write to debug file?"

      def call(entries_file:, bib_file:,  debug:)
        raise "Solr at #{AnnoyingUtilities.solr_url} not up" unless AnnoyingUtilities.solr_core.up?
        writer = select_writer(debug)

        logger.info "Clearing existing data"
        core.clear

        logger.info "Reloading core definition"
        core.reload

        logger.info "##### BEGIN ENTRY/QUOTE INDEXING #####"
        index(rulesfile: index_dir + 'main_indexing_rules.rb',
              datafile: entries_file,
              writer: writer)

        logger.info "##### BEGIN BIB INDEXING #####"

        index(rulesfile: index_dir + 'bib_indexing_rules.rb',
              datafile: bib_file,
              writer: writer)
        commit
        MedInstaller::Solr.rebuild_suggesters(core)
        optimize
        logger.info "Done"
      end

    end
  end
end

