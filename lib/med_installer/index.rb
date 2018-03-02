# require 'middle_english_dictionary'
require 'hanami/cli'
require 'pathname'
require 'annoying_utilities'
require 'med_installer/logger'
# require 'simple_solr_client'
# require 'semantic_logger'
# require 'med_installer/indexer/solr'
# require 'traject'


###### I'm not sure this is all worth it. Can just call traject directly,
# esp. wtih binstubs. Just need to make a reader.

module MedInstaller
  module Index
    class Entries < Hanami::CLI::Command
      include MedInstaller::Logger


      include AnnoyingUtilities

      desc "Index entries into solr using the traject configuration in indexer/main_indexer.rb"

      argument :datadir, required: true, desc: "The data directory. Contains '/xml' and '/json'"
      argument :dirname, required: false, desc: "Prefix of directories in datadir/json to index"

      INDEX_DIR = Pathname(__dir__).parent.parent + 'indexer'

      def call(datadir:, dirname: '[A-Z]')
        raise "Solr at #{solr.url} not up" unless solr.up?

      end
    end


  end
end
