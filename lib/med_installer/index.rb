# require 'middle_english_dictionary'
require 'hanami/cli'
require 'pathname'
require 'annoying_utilities'
require 'med_installer/logger'


module MedInstaller
  module Index
    class Entries < Hanami::CLI::Command
      include MedInstaller::Logger


      include AnnoyingUtilities

      desc "Index entries into solr using the traject configuration in indexer/main_indexer.rb"

      argument :filename, required: true, desc: "The location of entries.json"
      option :debug, type: :boolean, default: false, desc: "Write to debug file"
      INDEX_DIR = AnnoyingUtilities::DROMEDARY_ROOT + 'indexer'

      def call(filename:, debug:)
        raise "Solr at #{AnnoyingUtilities.solr_url} not up" unless AnnoyingUtilities.solr_core.up?

        index_dir = AnnoyingUtilities::DROMEDARY_ROOT + 'indexer'

        writer = if debug
                   index_dir  + 'writers' + 'debug.rb'
                 else
                   index_dir + 'writers' + 'localhost.rb'
                 end

        fields = index_dir + 'main_indexing_rules.rb'

        system "bundle", "exec", "traject",
               "-c", fields.to_s,
               "-c", writer.to_s,
               "-s", "med.data_file=#{filename}",
               "/dev/null", # traject requires a file on command line, no matter what
               out: $stdout, err: :out

        puts $?.exitstatus


        logger.info "Completed indexing. Sending commit and rebuilding autocompletes (long!)"

        core = AnnoyingUtilities.solr_core

        # Commit with index building can take a looooong time. Set the timeout to 100seconds
        core.rawclient.receive_timeout = 200_000 # 200 seconds
        core.commit

        logger.info "Optimizing solr index. Even longer!"
        core.optimize

        logger.info "Process complete"

      end
    end


  end
end
