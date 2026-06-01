require "middle_english_dictionary"
require "hanami/cli"
require "annoying_utilities"
require "simple_solr_client"

require_relative "logger"

require "my_simple_solr_client"

Zip.on_exists_proc = true

# update 2019_updates u, slip_rights sr
# set sr.attr = u.rights_current_attr
# where u.hyp_rights_attr <> sr.attr and u.full_id = sr.nid;

module MedInstaller
  # Namespace for Solr administration CLI commands.
  #
  # Contains a collection of {Hanami::CLI::Command} subclasses that interact
  # with the configured Solr instance: committing, optimizing, reloading,
  # clearing, and (for historical local-install workflows) downloading,
  # linking, starting, and stopping Solr.
  #
  # Several subclasses ({Install}, {Link}, {Start}, {Stop}) predate the
  # container-based deployment model and are candidates for removal.
  class Solr
    extend MedInstaller::Logger

    # @return [String] URL of the Solr 6.6.3 distribution tarball
    # @note Used only by {Install}, which is obsolete in containerised deployments.
    URL = "http://mirrors.gigenet.com/apache/lucene/solr/6.6.3/solr-6.6.3.tgz"

    # @return [String] name of the top-level directory extracted from the Solr tarball
    DIR_EXTRACTED_FROM_SOLR_TARGZ = "solr-6.6.3" # make this better!

    # @return [Pathname] absolute path to the Dromedary application root
    DROMEDARY_ROOT = AnnoyingUtilities::DROMEDARY_ROOT

    # @return [Pathname] path to the +solr/med/+ Solr core config directory
    MED_CONFIG = DROMEDARY_ROOT + "solr" + "med"

    # @return [Pathname] path to the +solr/lib/+ directory containing Solr plugins
    SOLR_LIBS = DROMEDARY_ROOT + "solr" + "lib"

    # @return [Pathname] path to the +.solr+ file that overrides the default
    #   Solr installation directory
    DOT_SOLR = AnnoyingUtilities::DOT_SOLR

    # @return [Pathname] default Solr installation directory (sibling of app root)
    DEFAULT_SOLR = AnnoyingUtilities::DEFAULT_SOLR

    # Returns the Solr port from the configured URL, with a fallback default.
    # @param rails_env [String] unused; kept for API compatibility
    # @return [String] the port number as a string
    # @note No references found in codebase — may be unused (Solr now runs in containers).
    def self.get_port_with_logging(rails_env)
      p = AnnoyingUtilities.solr_port
      if p
        logger.info "Got port #{p} from the solr url in blacklight_config.yml"
        p
      else
        logger.warn "Didn't find a port in the url string in blacklight.yml; using 9639"
        "9639"
      end
    end

    # Triggers a rebuild of all Solr suggest indexes configured in +autocomplete.yml+.
    # Hits each configured +solr_endpoint+ with +suggest.build=true+ via the Faraday connection.
    # @param core [Object] unused; kept for API compatibility (connection is built internally)
    # @param env [String, nil] Rails environment key for +autocomplete.yml+; defaults to +RAILS_ENV+
    # @return [void]
    # @note No references found in codebase — superseded by {IndexingSteps#rebuild_suggesters}.
    def self.rebuild_suggesters(core, env = nil)
      envenv = ENV["RAILS_ENV"]
      env ||= if envenv.nil? || envenv.empty?
        "development"
      else
        envenv
      end
      logger.info "Recreating suggest indexes for #{env} environment"
      autocomplete = AnnoyingUtilities.load_config_file("autocomplete.yml")[env]
      autocomplete.keys.each do |key|
        suggester_path = autocomplete[key]["solr_endpoint"]
        logger.info "   Recreate suggester for #{suggester_path}"
        # _resp = core.get "config/#{suggester_path}", {"suggest.build" => "true"}
        connection = MySimpleSolrClient::Client.new(Dromedary::Services[:solr_embedded_auth_url])
        connection.solr_connection.get suggester_path.to_s, {"suggest.build" => "true"}
      end
    end

    # CLI command that sends a commit request to the configured Solr core.
    #
    # Exits with status 1 if the core is not reachable.
    class Commit < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Force solr to commit"

      # @param cmd [String] unused positional argument required by Hanami::CLI
      # @return [void]
      def call(cmd)
        core = AnnoyingUtilities.solr_core

        unless core.up?
          logger.error "Solr core at #{core.url} did not respond (not up?)"
          exit(1)
        end

        core.commit
        logger.info "Core at '#{core.url}' sent commit"
      end
    end

    # CLI command that optimizes the Solr index (merges segments).
    #
    # This is a long-running operation. Exits with status 1 if the core is not reachable.
    class Optimize < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Optimize solr index"

      # @param cmd [String] unused positional argument required by Hanami::CLI
      # @return [void]
      def call(cmd)
        core = AnnoyingUtilities.solr_core

        unless core.up?
          logger.error "Solr core at #{core.url} did not respond (not up?)"
          exit(1)
        end

        logger.info "Begining optimization (can be *long*)"
        core.optimize
        logger.info "Core at '#{core.url}' optimized"
      end
    end

    # CLI command that reloads the Solr core config without restarting Solr.
    #
    # Exits with status 1 if the core is not reachable.
    class Reload < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Tell solr to reload the solr config without restarting"

      # @param cmd [String] unused positional argument required by Hanami::CLI
      # @return [void]
      def call(cmd)
        core = AnnoyingUtilities.solr_core

        unless core.up?
          logger.error "Solr core at #{core.url} did not respond (not up?)"
          exit(1)
        end

        core.reload
        logger.info "Core at '#{core.url}' reloaded"
      end
    end

    # CLI command that rebuilds all Solr autosuggest indexes.
    #
    # Delegates to {Solr.rebuild_suggesters}.
    class RebuildSuggesters < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Tell solr to rebuild all the suggester indexes"

      # @param cmd [String] unused positional argument required by Hanami::CLI
      # @return [void]
      def call(cmd)
        core = AnnoyingUtilities.solr_core
        Solr.rebuild_suggesters(core)
      end
    end

    # CLI command that deletes all documents from the Solr core.
    #
    # Exits with status 1 if the core is not reachable.
    class Empty < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Delete all documents in the solr"

      # @param cmd [String] unused positional argument required by Hanami::CLI
      # @return [void]
      def call(cmd)
        core = AnnoyingUtilities.solr_core
        unless core.up?
          logger.error "Solr core at #{core.url} did not respond (not up?)"
          exit(1)
        end
        core.clear.commit
        logger.info "Solr core at #{core.url} emptied out"
      end
    end

    # CLI command that downloads and installs a local copy of Solr 6.6.3.
    #
    # Downloads the distribution tarball from {URL}, extracts it, creates a
    # +solr+ symlink, records the path in +.solr+, and calls {Link} to wire in
    # the MED-specific configs.
    #
    # @note This command targets a pre-container workflow and is a candidate for
    #   removal. The current deployment uses a containerised Solr instance.
    class Install < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Download and install solr to the given directory"

      option :installdir, default: AnnoyingUtilities::DROMEDARY_ROOT.parent, desc: "The install directory (default: next to dromedary)"

      # @param installdir [String] directory to install Solr into
      # @return [void]
      # @raise [RuntimeError] if the download/extract or symlink steps fail
      def call(installdir:)
        installpath = Pathname(installdir).realdirpath
        solrpath = installpath + DIR_EXTRACTED_FROM_SOLR_TARGZ
        lnpath = installpath + "solr"
        solr_solr_dir = lnpath + "server" + "solr"
        _solr_config_dir = solr_solr_dir + "med"
        _solr_lib_dir = solr_solr_dir + "lib"

        logger.info "Download/extract from #{URL}"
        logger.info "Installing in directory #{installpath}"
        status = system(%(curl '#{URL}' | tar -C '#{installpath}' -x -z -f -))

        raise "Something went wrong with download / extract: #{status}" unless status

        logger.info "Making a symlink so we can use #{lnpath} instead of #{solrpath}"
        lncmd = "rm -f '#{lnpath}'; ln -s '#{solrpath}' '#{lnpath}'"
        status = system lncmd
        raise "Trouble symlinking #{solrpath} to #{lnpath}" unless status

        logger.info "Storing path to solr directory in dromedary/.solr"
        File.open(DOT_SOLR, "w:utf-8") do |out|
          out.puts lnpath.to_s
        end
        Link.new(command_name: "solr link").call("solr link")
      rescue => err
        logger.error err.message
        logger.error err.backtrace
        logger.error "Exiting"
        exit(1)
      end
    end

    # CLI command that symlinks MED Solr configs into the local Solr installation.
    #
    # Creates symlinks from the Solr installation's +server/solr/med+ and
    # +lib/+ directories to the MED-specific config and library paths.
    #
    # @note This command targets a pre-container workflow and is a candidate for
    #   removal. The current deployment uses a containerised Solr instance.
    class Link < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Link in the MED solr configurations to the solr in .solr"

      # @param cmd [String] unused positional argument required by Hanami::CLI
      # @return [void]
      # @raise [RuntimeError] if either symlink operation fails
      def call(cmd)
        solr_root = AnnoyingUtilities.solr_root
        solr_solr_dir = solr_root + "server" + "solr"
        solr_config_dir = solr_solr_dir + "med"
        solr_lib_dir = Pathname.new(AnnoyingUtilities.data_dir) + "lib"

        logger.info "Linking dromedary solr config stuff into the data dir"
        logger.info "Found solr directory #{solr_root}"
        logger.info "Linking  #{Solr::MED_CONFIG} into #{solr_config_dir}"
        status = system "rm -f '#{solr_config_dir}'; ln -s '#{Solr::MED_CONFIG}' '#{solr_config_dir}'"
        raise "Trouble linking #{Solr::MED_CONFIG} into the right place in solr" unless status

        logger.info "Linking in #{Solr::SOLR_LIBS}"
        status = system "rm -f '#{solr_lib_dir}'; ln -s '#{Solr::SOLR_LIBS}' '#{solr_lib_dir}'"
        raise "Trouble linking #{Solr::SOLR_LIBS}" unless status
        logger.info "Done"
      rescue => err
        logger.error err.message
        logger.error err.backtrace
        logger.error "Exiting"
        exit(1)
      end
    end

    # CLI command that starts a locally installed Solr instance.
    #
    # Reads the port from the blacklight Solr URL and invokes +bin/solr restart+.
    #
    # @note This command targets a pre-container workflow and is a candidate for
    #   removal. The current deployment uses a containerised Solr instance.
    class Start < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Start the solr referenced in .solr"
      argument :rails_env, required: false, default: "development", desc: "The rails environment"

      # @return [Pathname] path to the +bin/solr+ script in the installed Solr directory
      # @note No references found — Solr now runs in containers; this class may be vestigial.
      def solr_bin
        AnnoyingUtilities.solr_root + "bin" + "solr"
      end

      # @param rails_env [String] Rails environment name; used only to look up the port
      # @return [void]
      def call(rails_env:)
        port = Solr.get_port_with_logging(rails_env)
        portarg = "-p #{port}"
        command = "#{solr_bin} restart #{portarg} -Dsolr.solr.home=#{AnnoyingUtilities.solr_dir} -Ddromedary.data_dir=\"#{AnnoyingUtilities.data_dir}\""
        logger.info "Starting solr with command:\n  #{command}"
        system command
      end
    end

    # CLI command that stops a locally installed Solr instance.
    #
    # Inherits {#solr_bin} from {Start} and invokes +bin/solr stop+.
    #
    # @note This command targets a pre-container workflow and is a candidate for
    #   removal. The current deployment uses a containerised Solr instance.
    class Stop < Start
      argument :rails_env, default: "development", required: false, desc: "The rails environment"

      # @param rails_env [String] Rails environment name; used only to look up the port
      # @return [void]
      def call(rails_env:)
        port = Solr.get_port_with_logging(rails_env)
        portarg = "-p #{port}"
        system "#{solr_bin} stop #{portarg}"
      end
    end

    # CLI command that checks whether the configured Solr core is reachable.
    class Up < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Check to see if solr is up"

      # @param cmd [String] unused positional argument required by Hanami::CLI
      # @return [void]
      def call(cmd)
        core = AnnoyingUtilities.solr_core

        if core.up?
          logger.info "Solr at #{core.url} appears to be up and running"
        else
          logger.error "Solr core at #{core.url} did not respond (not up?)"
        end
      end
    end

    # CLI command that opens a Pry REPL connected to the configured Solr core.
    #
    # Optionally loads an entry set and/or a bib set into the session so they
    # can be explored interactively.
    class Shell < Hanami::CLI::Command
      desc "Get a shell connected to solr, optionally with collections"

      option :entries, required: false, desc: "Path to the entries.json.gz file (exposed as `entry_set`)"
      option :bibs, required: false, desc: "Path to the bib_all.xml (exposed as `bib_set`)"

      # @param entries [String, nil] path to +entries.json.gz+; when given, exposes
      #   an +entry_set+ local variable in the Pry session
      # @param bibs [String, nil] path to +bib_all.xml+; when given, exposes
      #   a +bib_set+ local variable in the Pry session
      # @param kw [Hash] additional keyword arguments (ignored)
      # @return [void]
      def call(entries: nil, bibs: nil, **kw)
        Up.new(command_name: "shell").call("shell")
        core = AnnoyingUtilities.solr_core

        entry_set = if entries
          settings = {
            "med.data_file" => entries
          }
          MedInstaller::EntryJsonReader.new(settings)
        end

        bib_set = if bibs
          MiddleEnglishDictionary::Collection::BibSet.new(filename: bibs)
        end

        require "pry"
        binding.pry # standard:disable Lint/Debugger
      end
    end
  end
end
