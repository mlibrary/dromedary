require "hanami/cli"
require "pathname"
require "annoying_utilities"
require "med_installer/logger"
require "med_installer/solr"
require "middle_english_dictionary/collection/bib_set"
require "traject"
require "json"

module MedInstaller
  # Hanami CLI commands that drive Traject-based indexing of MED data into Solr.
  #
  # The module contains a shared base class ({Generic}) plus four concrete
  # commands: {Entries}, {Bib}, {Full}, and {HypToBibID}.
  module Index
    # Base class for MED indexing CLI commands.
    #
    # Provides shared helpers for resolving file paths, choosing a Traject
    # writer, obtaining a Solr core connection, and running a Traject indexing
    # pass.  Concrete subclasses must override {#indexing_rules_file}.
    class Generic < Hanami::CLI::Command
      include MedInstaller::Logger
      include AnnoyingUtilities

      # @return [Pathname] path to the +indexer/+ directory under the app root
      def index_dir
        AnnoyingUtilities::DROMEDARY_ROOT + "indexer"
      end

      # Returns the path to the Traject rules file for this indexing command.
      # @abstract Subclasses must override this method.
      # @return [Pathname] path to the Traject indexing rules file
      # @raise [RuntimeError] always — must be implemented by the subclass
      def indexing_rules_file
        raise "Set in subclass"
      end

      # Selects the appropriate Traject writer config file.
      #
      # In debug mode returns a writer that logs records to a file instead of
      # sending them to Solr.
      #
      # @note The non-debug path writes to +writers/localhost.rb+, which targets
      #   a local Solr instance.  In containerised deployments the pipeline uses
      #   +Services[:solr_writer]+ instead; this method may be a candidate for
      #   removal.
      # @param debug [Boolean] when +true+, use the debug writer
      # @return [Pathname] path to the chosen Traject writer config file
      def select_writer(debug)
        _writer = if debug
          index_dir + "writers" + "debug.rb"
        else
          index_dir + "writers" + "localhost.rb"
        end
      end

      # Returns a configured Solr core connection with an extended receive timeout.
      #
      # Retrieves the Solr core via +AnnoyingUtilities.solr_core+ and raises the
      # raw client receive timeout to 200 seconds. Index-build commits can take
      # far longer than the default timeout, so this prevents premature failures
      # during large indexing runs.
      #
      # @return [Object] the Solr core client with receive timeout set to 200,000 ms
      def core
        core = AnnoyingUtilities.solr_core
        # Commit with index building can take a looooong time. Set the timeout to something long
        core.rawclient.receive_timeout = 200_000 # 200 seconds
        core
      end

      # Run a Traject indexing job against the MED data files.
      #
      # Loads the given rules and writer config files into a +Traject::Indexer+,
      # injects the data and bib file paths via indexer settings, then runs the
      # indexer. The input stream is opened from +File::NULL+ because Traject
      # expects a stream but the actual data paths are passed via settings.
      #
      # @param rulesfile [Pathname, String] path to the Traject rules/config file
      # @param datafile [Pathname, String] path to the MED XML data file
      # @param bibfile [Pathname, String] path to the bibliography data file
      # @param writer [Pathname, String] path to the Traject writer config file
      #   (e.g. a Solr writer or debug writer)
      # @return [void] logs the Traject exit status
      def index(rulesfile:, datafile:, bibfile:, writer:)
        indexer = ::Traject::Indexer.new
        indexer.settings do
          store "med.data_file", datafile.to_s
          store "bibfile", bibfile
        end

        indexer.load_config_file rulesfile.to_s
        indexer.load_config_file writer.to_s
        exitstatus = indexer.process(File.open(File::NULL))
        logger.info "Traject running #{rulesfile} exited with status #{exitstatus}"
      end

      # Verify Solr is reachable, then run the indexing rules file against the
      # appropriate data file.
      #
      # @param debug [Boolean] when +true+, use the debug writer instead of the
      #   Solr writer
      # @return [void]
      # @raise [RuntimeError] if the configured Solr instance is not responding
      def call(debug:)
        raise "Solr at #{AnnoyingUtilities.blacklight_solr_url} not up" unless AnnoyingUtilities.solr_core.up?
        writer = select_writer(debug)
        fields = indexing_rules_file
        index(rulesfile: fields, datafile: filename, writer: writer, bibfile: bibfile)
      end

      # Send a commit request to Solr via the configured core connection.
      # @return [void]
      def commit
        logger.info "Sending commit"
        core.commit
      end

      # Send an optimize request to Solr.  This is a long-running operation that
      # merges index segments and can take several minutes on large indexes.
      # @return [void]
      def optimize
        logger.info "Optimizing (long!)"
        core.optimize
      end
    end

    # -----

    # CLI command that indexes MED entry/quote documents into Solr.
    #
    # Uses +indexer/main_indexing_rules.rb+ as the Traject configuration and
    # first ensures the hyp-to-bib-ID mapping file is up to date by calling
    # {HypToBibID}.
    class Entries < Generic
      desc "Index entries into solr using the traject configuration in indexer/main_indexing_rules"

      option :debug, type: :boolean, default: false, desc: "Write to debug file?"

      # @return [Pathname] path to +indexer/main_indexing_rules.rb+
      def indexing_rules_file
        index_dir + "main_indexing_rules.rb"
      end

      # Build the hyp-to-bib-ID mapping, verify Solr is up, then run Traject
      # to index all entry documents.
      # @param debug [Boolean] when +true+, write output to a debug file
      # @return [void]
      def call(debug:)
        HypToBibID.new(command_name: "hyp_to_bib_id").call
        raise "Solr at #{AnnoyingUtilities.blacklight_solr_url} not up" unless AnnoyingUtilities.solr_core.up?
        writer = select_writer(debug)
        fields = indexing_rules_file
        index(rulesfile: fields, datafile: AnnoyingUtilities.entries_path, writer: writer, bibfile: AnnoyingUtilities.bibfile_path)
      end
    end

    # ------
    #

    # CLI command that indexes MED bibliography records into Solr.
    #
    # Uses +indexer/bib_indexing_rules.rb+, commits, and optimizes the index
    # after indexing completes.
    class Bib < Generic
      desc "Index entries into solr using the traject configuration in indexer/bib_indexing_rules"
      option :debug, type: :boolean, default: false, desc: "Write to debug file?"

      # @return [Pathname] path to +indexer/bib_indexing_rules.rb+
      def indexing_rules_file
        index_dir + "bib_indexing_rules.rb"
      end

      # Build the hyp-to-bib-ID mapping, verify Solr is up, index bib records,
      # commit, optimize, and commit again.
      # @param debug [Boolean] when +true+, write output to a debug file
      # @return [void]
      def call(debug:)
        HypToBibID.new(command_name: "hyp_to_bib_id").call
        raise "Solr at #{AnnoyingUtilities.blacklight_solr_url} not up" unless AnnoyingUtilities.solr_core.up?
        writer = select_writer(debug)
        index(rulesfile: index_dir + "bib_indexing_rules.rb",
          datafile:  AnnoyingUtilities.bibfile_path,
          writer:    writer,
          bibfile:   AnnoyingUtilities.bibfile_path)
        commit
        optimize
        commit
      end
    end

    #------

    # CLI command that performs a complete reload: clears Solr, indexes all
    # entries and bibliography records, rebuilds the autosuggest index,
    # optimizes, and toggles maintenance mode around the indexing run.
    class Full < Generic
      desc "Clear and reload solr, index entries and bib, build autosuggest, and optimize"
      option :debug, type: :boolean, default: false, desc: "Write to debug file?"
      option :existing_hyp_to_bibid, type: :boolean, default: false, desc: "Don't create new hyp_to_bibid"
      option :build_directory, type: :string, required: false,
        default: Dromedary::Services[:build_directory],
        desc: "The build directory (contains entries.json and xml/)"

      # Clear the Solr collection, reload the core definition, (optionally)
      # rebuild hyp-to-bib-ID, enable maintenance mode, index entries and bib,
      # rebuild suggesters, optimize, and disable maintenance mode.
      #
      # @param debug [Boolean] when +true+, write Traject output to debug file
      # @param existing_hyp_to_bibid [Boolean] when +true+, skip regenerating
      #   the hyp-to-bib-ID mapping (use the already-existing file)
      # @param build_directory [String] path to the build directory that
      #   contains +entries.json.gz+ and an +xml/+ subdirectory
      # @return [void]
      def call(debug:, existing_hyp_to_bibid:, build_directory:)
        raise "Solr at #{AnnoyingUtilities.blacklight_solr_url} not up" unless AnnoyingUtilities.solr_core.up?
        Dromedary::Services.register(:build_directory) { build_directory }
        writer = select_writer(debug)

        logger.info "Clearing existing data"
        core.clear

        logger.info "Reloading core definition"
        core.reload

        HypToBibID.new(command_name: "hyp_to_bib_id").call unless existing_hyp_to_bibid

        logger.info "Setting to maintenance mode during indexing"
        MedInstaller::Control::MaintenanceModeOn.new(command_name: "maintenance_mode on").call("on")

        logger.info "##### BEGIN ENTRY/QUOTE INDEXING #####"
        index(rulesfile: index_dir + "main_indexing_rules.rb",
          datafile:  AnnoyingUtilities.entries_path,
          writer:    writer,
          bibfile:   AnnoyingUtilities.bibfile_path)

        logger.info "##### BEGIN BIB INDEXING #####"

        index(rulesfile: index_dir + "bib_indexing_rules.rb",
          datafile:  AnnoyingUtilities.bibfile_path,
          writer:    writer,
          bibfile:   AnnoyingUtilities.bibfile_path)
        commit
        MedInstaller::Solr.rebuild_suggesters(core)
        commit
        optimize
        logger.info "Done"
        logger.info "New data in place. Making the site live again."
        MedInstaller::Control::MaintenanceModeOff.new(command_name: "maintenance_mode off").call("off")
      end
    end

    # -----

    # CLI command that builds and persists the HYP-ID-to-bib-ID mapping.
    #
    # MED entries reference bibliography records via "HYP" identifiers (RIDs).
    # This command reads +bib_all.xml+, builds a +{hyp_id => bib_id}+ hash,
    # and writes it as JSON to the path returned by
    # +AnnoyingUtilities.hyp_to_bibid_path+.
    #
    # @note +AnnoyingUtilities.hyp_to_bibid_path+ is referenced here but that
    #   method is not defined in +annoying_utilities.rb+ — this command will
    #   raise +NoMethodError+ at runtime.
    class HypToBibID < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Create the mapping from HYP ids (RID) to bib IDs"

      # Returns (or builds and memoizes) a {MiddleEnglishDictionary::Collection::BibSet}
      # loaded from the given bibliography XML file.
      # @param filename [Pathname, String] path to +bib_all.xml+
      # @return [MiddleEnglishDictionary::Collection::BibSet]
      def bibset(filename)
        @bibset ||= MiddleEnglishDictionary::Collection::BibSet.new(filename: filename)
      end

      # Builds and memoizes the HYP-ID-to-bib-ID mapping hash.
      #
      # Iterates over every bib record and every HYP identifier it carries,
      # stripping backslashes and uppercasing the key before storing it.
      #
      # @return [Hash{String => String}] mapping of HYP IDs to bib IDs
      def hyp_to_bibid
        return @hyp_to_bibid if @hyp_to_bibid
        logger.info "Building hyp_to_bibid mapping"
        bibfile = Pathname.new(Dromedary::Services[:build_directory]) + "xml" + "bib_all.xml"
        @hyp_to_bibid ||= bibset(bibfile).each_with_object({}) do |bib, acc|
          bib.hyps.each do |hyp|
            acc[hyp.delete("\\").upcase] = bib.id # TODO: Take out when backslashes removed from HYP ids
          end
        end
      end

      # Serialises the {#hyp_to_bibid} mapping to JSON and writes it to disk.
      # @return [void]
      # @raise [NoMethodError] +AnnoyingUtilities.hyp_to_bibid_path+ is not
      #   defined — this will fail at runtime until the method is added.
      def write_hyp_to_bib_id
        logger.info "Creating and writing hyp_to_bibid mapping at #{AnnoyingUtilities.hyp_to_bibid_path}"
        File.open(AnnoyingUtilities.hyp_to_bibid_path, "w:utf-8") do |out|
          out.puts hyp_to_bibid.to_json
        end
      end

      # Entry point: build and persist the hyp-to-bib-ID mapping.
      # @param command_name [String] display name for log messages
      # @return [void]
      def call(command_name: "HypToBibID")
        logger.info "Creating hyp_to_bibid.json"
        write_hyp_to_bib_id
      end
    end
  end
end
