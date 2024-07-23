# frozen_string_literal: true

require "dromedary/services"
require "date_named_file"
require "solr_cloud/connection"
require "med_installer/extract"
require "med_installer/convert"
require "solr_cloud/connection"

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
    attr_accessor :data_root, :build_dir
    Services = Dromedary::Services

    def initialize(data_root = Services.data_root, build_dir = Services.build_directory)
      @data_root = data_root
      @build_dir = build_dir
    end

    def index(filename: most_recent_zip_file)
      prepare_build_directory
      extract_zip_to_build_directory
      verify_unzipped_files!
      create_solr_documents
      create_solr_collection_for_indexing!
    end

    def most_recent_zip_file(data_dir: data_root)
      Pathname(data_root) + "tiny-set.zip" # TODO
    end

    # Make sure all the directories we're going to use exist
    def prepare_build_directory(build_dir: Services[:build_directory])
      bdir = Pathname.new(build_dir).realdirpath
      xmldir = bdir + "xml"
      bdir.mkpath
      xmldir.mkpath
    end

    # Recursively extract data from the zipfile
    def extract_zip_to_build_directory(zipfile: most_recent_zip_file, build_directory: build_dir)
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
    def create_solr_documents(build_directory: build_dir)
      MedInstaller::Convert.new(command_name: "convert").call(build_directory: build_directory)
    end

    # Create a new collection for this build. This will upload the configuration, create
    # the collection, and then return the full URL to that collection.
    # @param collection_name [String] The name of the collection to create
    # @param solr_root [String] URL to the root of the solr service (https://blah/solr)
    # @param solr_username [String] Solr login username
    # @param solr_password [String] Solr login password
    # @param solr_configuration_directory [String, Pathname] Local path to solr `conf` directory
    # @return [String] URL to the solr collection
    def create_solr_collection_for_indexing!(collection_name: Services.build_solr_collection_name,
      solr_root: Services.solr_root,
      solr_username: Services.solr_username,
      solr_password: Services.solr_password,
      solr_configuration_directory: Services.solr_conf_directory)

      sroot = SolrCloud::Connection.new(url: solr_root, user: solr_username, password: solr_password)
      unless sroot.has_configset?(collection_name)
        sroot.create_configset(name: collection_name, confdir: solr_configuration_directory)
      end
      unless sroot.has_collection?(collection_name)
        sroot.create_collection(name: collection_name, configset: collection_name)
      end
      sroot.get_collection(collection_name).url
    end

    def generic_indexing_call(rulesfile:,
      datafile:,
      bib_all_file: Services[:bib_all_file],
      writer: Services[:solr_writer])
      indexer = ::Traject::Indexer.new
      indexer.settings do
        store "med.data_file", datafile.to_s
        store "bibfile", bib_all_file
      end

      indexer.load_config_file rulesfile.to_s
      indexer.load_config_file writer.to_s
      exitstatus = indexer.process(File.open("/dev/null"))
      logger.info "Traject running #{rulesfile} exited with status #{exitstatus}"
    end

    # Actually index the documents in entries.json.gz
    # @param entries_filename [String] Path to entries.json.gz
    def index_entries
      generic_indexing_call(rulesfile: Dromedary::Services[:entry_indexing_rules],
        datafile: Dromedary::Services[:entries_gz_file])
    end

    def index_bibs
      generic_indexing_call(rulesfile: Dromedary::Services[:bib_indexing_rules],
        datafile: Dromedary::Services[:bib_all_xml_file])
    end
  end
end
