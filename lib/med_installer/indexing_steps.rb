# frozen_string_literal: true

require "dromedary/services"
require "date_named_file"
require "solr_cloud/connection"
require "med_installer/extract"
require "med_installer/convert"
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
    attr_reader :data_root, :build_dir, :xml_dir, :uid, :zipfile, :connection
    Services = Dromedary::Services
    include SemanticLogger::Loggable

    def initialize(data_root = Services.data_root,
                   build_dir = Services.build_directory,
                   connection: Services[:solr_connection],
                   zipfile: nil)
      @data_root = data_root
      @build_dir = Pathname.new(build_dir).realdirpath
      @xml_dir = @build_dir + "xml"
      @connection = connection

      @zipfile ||= most_recent_zip_file
      @uid = uid(@zipfile)

      @coll_conf_name = Services.build_solr_collection_name

    end

    def index
      check_to_see_if_this_file_has_already_been_indexed!

      prepare_build_directory
      extract_zip_to_build_directory
      verify_unzipped_files!

      create_solr_documents

      @build_collection = create_configset_and_collection!
      collection_url = @build_collection.connection.url.chomp("/") + "/solr/#{@build_collection.name}"
      logger.info "Going to index targeting #{collection_url}"
      index_entries(solr_url: collection_url)
      index_bibs(solr_url: collection_url)
      @build_collection.commit
      rebuild_suggesters(solr_url: collection_url)
      @build_collection.commit
    end

    def check_to_see_if_this_file_has_already_been_indexed!
      existing_index = existing_index_for_this_zipfile
      if existing_index
        msg = "File '#{zipfile}' appears to have already been indexed, based on sharing an MD5 digest."
        raise msg
      end
    end

    # Check to see if we've already created an index based on this file
    # (as envidenced by the digest string being a part of a collection name)
    # @return [String, nil] Name of the existing collection, or nil
    def existing_index_for_this_zipfile
      @connection.collection_names.grep(Regexp.new(digest)).first
    end

    def digest(file = @zipfile)
      @digest ||= Digest::MD5.file(file).hexdigest
    end

    def uid(file = @zipfile)
      [Services[:solr_collection_base], digest(file), Services[:build_date_suffix]].join("_")
    end

    # TODO: Use the real name, and put the path to it in Services based on a NEW_DATA_FILE_NAME
    # or somehting like that.
    # TODO: All that shit doesn't need to live in Services. Pull the build-specific stuff out here.
    def most_recent_zip_file(dir: @data_root)
      Pathname(dir) + "tiny-set.zip" # TODO
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
    def create_solr_documents(build_directory: build_dir)
      MedInstaller::Convert.new(command_name: "convert").call(build_directory: build_directory)
    end

    def create_configset_and_collection!(uid: @uid, solr_configuration_directory: Services.solr_conf_directory)
      connection.create_configset(name: uid, confdir: solr_configuration_directory)
      connection.create_collection(name: uid, configset: uid)
      connection.get_collection(uid)
    end

    #
    # # Create a new collection for this build. This will upload the configuration, create
    # # the collection, and then return the full URL to that collection.
    # # @param collection_name [String] The name of the collection to create
    # # @param solr_root [String] URL to the root of the solr service (https://blah/solr)
    # # @param solr_username [String] Solr login username
    # # @param solr_password [String] Solr login password
    # # @param solr_configuration_directory [String, Pathname] Local path to solr `conf` directory
    # # @return [SolrCloud::Connection::Collection] Name of the new solr collection
    # def create_solr_collection_for_indexing!(collection_name: @coll_conf_name,
    #                                          solr_root: Services.solr_root,
    #                                          solr_username: Services.solr_username,
    #                                          solr_password: Services.solr_password,
    #                                          solr_configuration_directory: Services.solr_conf_directory)
    #
    #   sroot = SolrCloud::Connection.new(url: solr_root, user: solr_username, password: solr_password)
    #   if sroot.has_configset?(collection_name)
    #     logger.warn "Configset #{collection_name} already existed; using it"
    #   else
    #     sroot.create_configset(name: collection_name, confdir: solr_configuration_directory)
    #     logger.info "Created collection #{collection_name} based on directory #{solr_configuration_directory}"
    #   end
    #
    #   if sroot.has_collection?(collection_name)
    #     raise "Won't index into an existing collection, and '#{collection_name}' already exists. Aborting"
    #   else
    #     sroot.create_collection(name: collection_name, configset: collection_name)
    #   end
    #   sroot.get_collection(collection_name)
    # end

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
      exitstatus = indexer.process(File.open("/dev/null"))
      logger.info "Traject running #{rulesfile} exited with status #{exitstatus}"
    end

    # Actually index the documents in entries.json.gz
    # @param entries_filename [String] Path to entries.json.gz
    def index_entries(solr_url:)
      generic_indexing_call(rulesfile: Dromedary::Services[:entry_indexing_rules],
                            datafile: Dromedary::Services[:entries_gz_file],
                            solr_url: solr_url)
    end

    def index_bibs(solr_url:)
      generic_indexing_call(rulesfile: Dromedary::Services[:bib_indexing_rules],
                            datafile: Dromedary::Services[:bib_all_xml_file], solr_url: solr_url)
    end

    def rebuild_suggesters(solr_url:, env: "production")
      logger.info "Recreating suggest indexes"
      autocomplete_filename = Services[:root_directory] + "config" + "autocomplete.yml"
      autocomplete_map = YAML.safe_load(ERB.new(File.read(autocomplete_filename)).result, aliases: true)[env]
      autocomplete_map.keys.each do |key|
        suggester_path = autocomplete_map[key]["solr_endpoint"]
        logger.info "   Recreate suggester for #{suggester_path}"
        resp = @build_collection.get "solr/#{@build_collection.name}/#{suggester_path}", { "suggest.build" => "true" }
      end
    end

  end
end
