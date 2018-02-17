require 'middle_english_dictionary'
require 'hanami/cli'
require 'pathname'
require 'annoying_utilities'
require 'simple_solr_client'
require 'semantic_logger'
require 'med_installer/indexer/solr'


module MedInstaller
  class Indexer < Hanami::CLI::Command

    include AnnoyingUtilities

    desc "Convert the xml files into (faster) json objects (takes a long time)"

    argument :datadir, required: true, desc: "The data directory. Contains '/xml' and '/json'"
    argument :traject_file, required: true, desc: "Path to the traject config file"
    argument :dirname, required: false, desc: "Prefix of directories in datadir/json to index"

    INDEX_DIR = Pathname(__dir__).parent.parent + 'indexer'

    def call(datadir:, traject_file:, dirname: '[A-Z]')
      raise "Solr at #{solr.url} not up" unless solr.up?

      indexer = traject_indexer(traject_file)

      target_directories(datadir, dirname).each do |d|
        entries = load_entries(d)

      end
    end

    def load_entries(dir)
      logger.info "Reading from #{dir}..."
      entries = MiddleEnglishDictionary::Collection::EntrySet.new.load_dir_of_json_files(dir)
      logger.info "Indexing #{dir} with #{entries.count} entries"
      entries
    end

    def target_directories(datadir, dirname)
      jsondir = Pathname(datadir) + 'json'
      regexp  = Regexp.new "\\/#{dirname}.*\\Z", 'x'
      jsondir.children.select {|x| x.directory? and regexp.match(x.to_s)}
    end

    def solr
      @solr ||= MedInstaller::Indexer::Solr.new
    end

    # Need to wrap the written hash in a structure that responds to
    # #context_hash because of how Traject 2.x deals with writers
    StupidCHStruct = Struct.new(:context_hash)

    def write(h)
      writer.put StupidCHStruct.new(h)
    end


    def writer
      @writer ||= Traject::SolrJsonWriter.new('solr.url' => solr_url, 'solr_writer.commit_on_close' => true)
    end

    def logger
      SemanticLogger[Index]
    end


  end
end
