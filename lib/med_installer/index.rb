# require 'middle_english_dictionary'
require 'hanami/cli'
require 'pathname'
require 'annoying_utilities'
require 'med_installer/logger'


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

      def commit
        core.commit
      end

      def optimize
        core.optimize
      end

      def call(filename:, debug:)
        raise "Solr at #{AnnoyingUtilities.solr_url} not up" unless AnnoyingUtilities.solr_core.up?
        writer = select_writer(debug)
        fields = indexing_rules_file
        system "bundle", "exec", "traject",
               "-c", fields.to_s,
               "-c", writer.to_s,
               "-s", "med.data_file=#{filename}",
               "/dev/null", # traject requires a file on command line, no matter what
               out: $stdout, err: :out
        puts $?.exitstatus

        logger.info "Completed indexing. Sending commit"
        commit
        logger.info "Optimizing (long!)"
        core.optimize

        logger.info "Process complete"
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

  end
end
