# frozen_string_literal: true

require "dromedary/services"
require "date_named_file"
require "solr_cloud/connection"
require "med_installer/extract"
require "med_installer/convert"
require "med_installer/hyp_to_bibid"
require "solr_cloud/connection"
require "traject"

module MedInstaller
  # Run a complete indexing workflow, including
  # * Find the new .zip file to index and extract it into individual files in
  #   Services.build_directory (date-named directory under DATA_ROOT/build).
  #   This recursively extracts the xml files.
  # * Convert the data from the zip file into entries, saved as solr documents
  #   in entries.json.gz
  # * Create a new `hyp_to_bibid.json` in Services.build_directory, based on
  #   the xml/bib_all.xml file.
  # * Create a new solr core for the indexing, date-named, at SOLR_ROOT
  # * Index the dictionary entries (from entries.json.gz)
  # * Index the bibliographic entries (from bib_all.xml)
  # * Hard commit
  # * Rebuild the solr suggesters
  # * Optimize
  # This class is basically piggy-backing on the work done for the `bin/dromedary` CLI,
  # but with less redirection and more stuff pulled from the Services object
  class IndexingSteps
    attr_reader :build_dir, :xml_dir, :uid, :zipfile, :connection
    Services = Dromedary::Services
    include SemanticLogger::Loggable

    def initialize(zipfile:,
                   build_dir: Services.build_directory,
                   connection: Services[:solr_connection]
                   )
      @build_dir = Pathname.new(build_dir).realdirpath
      @xml_dir = @build_dir + "xml"
      @connection = connection
      @zipfile = zipfile
      @coll_and_configset_name = Services.name_of_solr_collection_to_index_into

    end

    def index
      prepare_build_directory
      extract_zip_to_build_directory
      verify_unzipped_files!

      @build_collection = create_configset_and_collection!

      # Delete any leftover crap from when we had different aliases.
      @connection.aliases.each do |a|
        a.delete! unless [Dromedary::Services[:production_alias], Dromedary::Services[:preview_alias]].include? a.name
      end

      create_unified_documents

      # TODO: SolrCloud::Collection should have a `#url` method, for god's sake
      collection_url = @build_collection.connection.url.chomp("/") + "/solr/#{@build_collection.name}"

      logger.info "Uploading hyp_to_bibid to the new collection"
      upload_hyp_to_bibid_to_solr
      @build_collection.commit

      logger.info "Going to index targeting #{collection_url}"
      index_entries(solr_url: collection_url)
      index_bibs(solr_url: collection_url)
      rebuild_suggesters

      logger.info "Cleaning up"
      @build_dir.rmtree

      logger.info "Point #{Services[:preview_alias]} at the new #{@build_collection.name} collection "
      preview_alias = connection.get_alias(Dromedary::Services[:preview_alias])
      preview_alias && preview_alias.delete!
      @build_collection.alias_as(Services[:preview_alias], force: true)
    end

    # Make sure all the directories we're going to use exist
    def prepare_build_directory
      build_dir.mkpath
      xml_dir.mkpath
    end

    # Recursively extract data from the zipfile
    def extract_zip_to_build_directory(zipfile: @zipfile, build_directory: @build_dir)
      MedInstaller::Extract.new(command_name: "extract").call(zipfile: zipfile, build_directory: build_directory)
    end

    # Make sure the zipfile produced the stuff we're expecting, at least cursorily.
    # As opposed to doing it right, we'll just look for:
    #   * bib_all.xml
    #   * MED2DOE*xml and MED2OED*xml
    def verify_unzipped_files!(build_directory = build_dir)
      xml_dir = Pathname.new(build_directory) + "xml"
      files = xml_dir.children.map(&:basename).map(&:to_s)
      raise "Can't find bib_all.xml in #{xml_dir}" unless files.include?("bib_all.xml")
      raise "Can't find MED2OED links file in #{xml_dir}" if files.grep(/MED2OED.*xml/).empty?
      raise "Can't find MED2DOE links file in #{xml_dir}" if files.grep(/MED2DOE.*xml/).empty?
    end

    # Build up the entries, based on the xml files along with the oed/doe linkage files
    # This:
    #   * creates entries.json.gz in the build_directory (build in tmp, then copied)
    #   * creates the hyp_to_bibid.json file in the build directory, based on the bib_all.xml file
    def create_unified_documents(build_directory: build_dir)
      MedInstaller::Convert.new(command_name: "convert").call(build_directory: build_directory)
    end


    # @return [SolrCloud::Collection]
    def create_configset_and_collection!(name: @coll_and_configset_name,
                                         solr_configuration_directory: Services.solr_conf_directory,
                                         replication_factor: Services[:solr_replication_factor])
      logger.info "Creating configset/collection #{name}, replication factor #{replication_factor}"
      connection.create_configset(name: name, confdir: solr_configuration_directory)
      connection.create_collection(name: name, configset: name, replication_factor: replication_factor)
      connection.get_collection(name)
    end

    def generic_indexing_call(rulesfile:,
                              datafile:,
                              solr_url:,
                              bib_all_xml_file: Services[:bib_all_xml_file],
                              writer: Services[:solr_writer])
      indexer = ::Traject::Indexer.new
      indexer.settings do
        store "med.data_file", datafile.to_s
        store "bibfile", bib_all_xml_file
        store "solr.url", solr_url
      end

      indexer.load_config_file rulesfile.to_s
      indexer.load_config_file writer.to_s
      null_file_because_the_real_data_file_is_stored_in_med_dot_data_file = File.open("/dev/null")
      exitstatus = indexer.process(null_file_because_the_real_data_file_is_stored_in_med_dot_data_file)
      logger.info "Traject running #{rulesfile} exited with status #{exitstatus}"
      exitstatus
    end

    # Actually index the documents in entries.json.gz
    # @param solr_url[String]
    # @return [Integer] exit status
    def index_entries(solr_url:)
      generic_indexing_call(rulesfile: Dromedary::Services[:entry_indexing_rules],
                            datafile: Dromedary::Services[:entries_gz_file],
                            solr_url: solr_url)
    end

    # Actually index the bibs as expressed in bib_all.xml
    # @param solr_url[String]
    # @return [Integer] exit status
    def index_bibs(solr_url:)
      generic_indexing_call(rulesfile: Dromedary::Services[:bib_indexing_rules],
                            datafile: Dromedary::Services[:bib_all_xml_file], solr_url: solr_url)
    end

    # Rebuild the suggesters that provide autocomplete/typeahead functionality for @build_collection
    # @param rails_env [String] "production" or "development"
    def rebuild_suggesters(rails_env: (ENV["RAILS_ENV"] || "production"))
      logger.info "Recreating suggest indexes"
      logger.info "  Start with a hard commit"
      @build_collection.commit(hard: true)

      autocomplete_filename = Services[:root_directory] + "config" + "autocomplete.yml"
      autocomplete_map = YAML.safe_load(ERB.new(File.read(autocomplete_filename)).result, aliases: true)[rails_env]
      autocomplete_map.keys.each do |key|
        suggester_path = autocomplete_map[key]["solr_endpoint"]
        logger.info "   Recreate suggester for #{suggester_path}"
        resp = @build_collection.get "solr/#{@build_collection.name}/#{suggester_path}", { "suggest.build" => "true" }
      end
      logger.info "   ...and finish with another hard commit"
      @build_collection.commit(hard: true)
    end

    # Send the new hyp_to_bibid.json file to the currently defined build_collection
    def upload_hyp_to_bibid_to_solr
      filepath = Pathname.new(@build_dir) + "hyp_to_bibid.json"
      MedInstaller::HypToBibId.dump_file_to_solr(collection: @build_collection, filename: filepath.to_s)
    end
  end
end

