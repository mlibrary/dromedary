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

      argument :datadir, required: true, desc: "The data directory. Contains '/xml' and '/json'"
      argument :dirname, required: false, default: '[A-Z]', desc: "Prefix of directories in datadir/json to index"

      INDEX_DIR = AnnoyingUtilities::DROMEDARY_ROOT + 'indexer'

      def call(datadir:, dirname:)
        raise "Solr at #{AnnoyingUtilities.solr_url} not up" unless AnnoyingUtilities.solr_core.up?

        index_dir = AnnoyingUtilities::DROMEDARY_ROOT + 'indexer'
        writer    = index_dir + 'writers' + 'localhost.rb'
        fields    = index_dir + 'entry_indexer.rb'

        system "bundle", "exec", "traject",
               "-c", fields.to_s,
               "-c", writer.to_s,
               "-s", "med.data_dir=#{datadir}",
               "-s", "med.letters=#{dirname}",
               "/dev/null", # traject requires a file on command line, no matter what
               out: $stdout, err: :out

        puts $?.exitstatus

      end
    end


  end
end
