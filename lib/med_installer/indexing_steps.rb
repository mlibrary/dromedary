# frozen_string_literal: true

require "dromedary/services"
require "date_named_file"
require "solr_cloud/connection"
require "med_installer/extract"
require "med_installer/convert"
require "med_installer/hyp_to_bibid"
require "solr_cloud/connection"
require "traject"
require "yaml"

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
      @coll_and_configset_name = Services[:name_of_solr_collection_to_index_into]
    end

    def index

      # Do some basic checks against the solr

      url = Dromedary::Services[:solr_url]
      connection_url = @connection.url
      logger.info "Trying to connect to #{Dromedary::Services[:solr_url]}"
      logger.info "Connection thinks its url is #{@connection.url}"
      logger.debug "System: #{@connection.system.to_yaml}\n\n"

      # We were dealing with some instabilities in the k8s cluster in 2024.09 when we wanted
      # to release this, resulting nodes loosing track of zookeeper and suggesters not getting
      # built (calls would time out). Attempt to brute-force this by hitting the individual
      # solr URLs directly, taking advantage of knowledge about how many replicas and what
      # they're called that we'd really rather not have to know.
      #
      # If things are working as planned, we can just make the single call to
      # `rebuild_suggesters` and accept the default connection and call it a day.
      #
      # To run in once for each configured solr replica, we need the following:
      # * ENV[DIRECT_URLS_TO_SOLR_REPLICAS]: A space-delimited set of urls of the form
      #   "http://solr-solrcloud-1:8083" or whatever. This is the same format as the
      #   generic (cluster-level) connection string found in ENV[SOLR_URL]
      # * A non-falsey value for ENV[MANUALLY_BUILD_SUGGESTERS] to enable it.
      # @dueberb 2024.09.17

      logger.info "Checking to see if we should try to build suggesters on each solr replica individually"
      direct_urls_string = Services[:direct_urls_to_solr_replicas]
      if direct_replica_urls and Services[:manually_build_suggesters]
        logger.info "Will target #{direct_replica_urls.count} replicas for 'manual' builds of suggester index:"
        direct_replica_urls.each do |u|
          logger.info "- '#{u}'"
        end
      else
        logger.info "Nope. Will just target the single logical solr url"
      end

      prepare_build_directory
      extract_zip_to_build_directory
      verify_unzipped_files!

      @build_collection = create_configset_and_collection!

      # Delete any leftover crap from when we had different aliases.
      @connection.aliases.each do |a|
        a.delete! unless [Dromedary::Services[:production_alias], Dromedary::Services[:preview_alias]].include? a.name
      end

      create_combined_documents

      # TODO: SolrCloud::Collection should have a `#url` method, for god's sake
      collection_url = @build_collection.connection.url.chomp("/") + "/solr/#{@build_collection.name}"

      logger.info "Uploading hyp_to_bibid to the new collection"
      upload_hyp_to_bibid_to_solr
      @build_collection.commit

      logger.info "Begin indexing, targeting #{collection_url}"
      index_entries(solr_url: collection_url)
      index_bibs(solr_url: collection_url)

      @build_collection.commit

      if direct_replica_urls and Services[:manually_build_suggesters]
        urls = direct_replica_urls
        pause_time = (ENV["PAUSE_TIME"] || 60).to_i
        half_pause_time = pause_time / 2
        logger.info "Sleeping for #{pause_time} seconds so things can crash and restart if that's what they're doing."
        sleep half_pause_time # Let whatever restarts are going to happen, happen.
        logger.info "...#{half_pause_time}"
        sleep (pause_time - half_pause_time)
        logger.info "...#{pause_time}"
        urls.each do |direct_url|
          logger.info "Rebuild suggesters at '#{direct_url}'"
          conn = SolrCloud::Connection.new(url: direct_url, user: @connection.user, password: @connection.password)
          rebuild_suggesters(connection: conn)
        end
      else
        logger.info "Rebuilding suggesters against just the default #{@connection}"
        rebuild_suggesters # This is the "happy path" if the k8s cluster is behaving
      end

      @build_collection.commit

      logger.info "Cleaning up: remove temporary files"
      @build_dir.rmtree

      logger.info "Point #{Services[:preview_alias]} at the new #{@build_collection.name} collection "
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
    def create_combined_documents(build_directory: build_dir)
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
    def rebuild_suggesters(rails_env: (ENV["RAILS_ENV"] || "production"),
                           collection_name: @build_collection.name,
                           connection: @connection)
      logger.info "Recreating suggest indexes for #{collection_name}"
      autocomplete_filename = Services[:root_directory] + "config" + "autocomplete.yml"
      autocomplete_map = YAML.safe_load(ERB.new(File.read(autocomplete_filename)).result, aliases: true)[rails_env]
      autocomplete_map.keys.each do |suggester_name|
        suggester_path = autocomplete_map[suggester_name]["solr_endpoint"]
        logger.info "   Recreate suggester for #{suggester_name} in #{collection_name} at #{connection.url}"
        begin
          resp = connection.get "solr/#{collection_name}/#{suggester_path}", { "suggest.build" => "true" }
        rescue => e
          raise "Error trying to build suggester : #{e.message}"
        end
      end
    end

    # Send the new hyp_to_bibid.json file to the currently defined build_collection
    def upload_hyp_to_bibid_to_solr
      filepath = Pathname.new(@build_dir) + "hyp_to_bibid.json"
      MedInstaller::HypToBibId.dump_file_to_solr(collection: @build_collection, filename: filepath.to_s)
    end

    # Parse out URLS
    def direct_replica_urls
      return nil unless Services[:direct_urls_to_solr_replicas] && (Services[:direct_urls_to_solr_replicas] =~ /\S/)
      Services[:direct_urls_to_solr_replicas].split(/\s+/).map{|x| x.strip}.reject{|x| x == "" or x.nil?}
    end

  end
end

