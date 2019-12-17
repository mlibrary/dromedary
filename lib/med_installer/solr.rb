require 'middle_english_dictionary'
require 'hanami/cli'
require 'annoying_utilities'
require 'simple_solr_client'

require_relative "logger"

Zip.on_exists_proc = true


# update 2019_updates u, slip_rights sr
# set sr.attr = u.rights_current_attr
# where u.slip_rights_attr <> sr.attr and u.full_id = sr.nid;

module MedInstaller
  class Solr
    extend MedInstaller::Logger
    URL                           = 'http://mirrors.gigenet.com/apache/lucene/solr/6.6.3/solr-6.6.3.tgz'
    DIR_EXTRACTED_FROM_SOLR_TARGZ = 'solr-6.6.3' # make this better!

    DROMEDARY_ROOT = AnnoyingUtilities::DROMEDARY_ROOT
    MED_CONFIG     = DROMEDARY_ROOT + 'solr' + 'med'
    SOLR_LIBS      = DROMEDARY_ROOT + 'solr' + 'lib'
    DOT_SOLR       = AnnoyingUtilities::DOT_SOLR
    DEFAULT_SOLR   = AnnoyingUtilities::DEFAULT_SOLR


    def self.get_port_with_logging(rails_env)
      p    = AnnoyingUtilities.solr_port
      port = if p
               logger.info "Got port #{p} from the solr url in blacklight_config.yml"
               p
             else
               logger.warn "Didn't find a port in the url string in blacklight.yml; using 9639"
               "9639"
             end
      port
    end

    def self.rebuild_suggesters(core, env = nil)
      envenv = ENV['RAILS_ENV']
      env    ||= if envenv.nil? or envenv.empty?
                   'development'
                 else
                   envenv
                 end
      logger.info "Recreating suggest indexes for #{env} environment"
      autocomplete = AnnoyingUtilities.load_config_file('autocomplete.yml')[env]
      autocomplete.keys.each do |key|
        suggester_path = autocomplete[key]["solr_endpoint"]
        logger.info "   Recreate suggester for #{suggester_path}"
        resp = core.get "/#{suggester_path}", {'suggest.build' => 'true'}
      end
    end

    class Commit < Hanami::CLI::Command
      include MedInstaller::Logger
      desc "Force solr to commit"

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

    class Optimize < Hanami::CLI::Command
      include MedInstaller::Logger
      desc "Optimize solr index"

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

    class Reload < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Tell solr to (re)load the solr config without restarting"

      def call(cmd)
        client = AnnoyingUtilities.solr_client
        core = AnnoyingUtilities.solr_core

        if core.up?
          core.reload
          logger.info "Core at '#{core.url}' reloaded"
        else
          # curl "${SOLR_ROOT}/admin/cores?action=CREATE&name=$core&config=solrconfig.xml&dataDir=data&instanceDir=$dir&wt=json
        end

      end
    end

    class RebuildSuggesters < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Tell solr to rebuild all the suggester indexes"

      def call(cmd)
        core = AnnoyingUtilities.solr_core
        Solr.rebuild_suggesters(core)
      end

    end


    class Empty < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Delete all documents in the solr"

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

    class Install < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Download and install solr to the given directory"

      option :installdir, default: AnnoyingUtilities::DROMEDARY_ROOT.parent, desc: "The install directory (default: next to dromedary)"

      def call(installdir:)
        installpath     = Pathname(installdir).realdirpath
        solrpath        = installpath + DIR_EXTRACTED_FROM_SOLR_TARGZ
        lnpath          = installpath + 'solr'
        solr_solr_dir   = lnpath + 'server' + 'solr'
        solr_config_dir = solr_solr_dir + 'med'
        solr_lib_dir    = solr_solr_dir + 'lib'

        logger.info "Download/extract from #{URL}"
        logger.info "Installing in directory #{installpath}"
        status = system(%Q{curl '#{URL}' | tar -C '#{installpath}' -x -z -f -})

        raise "Something went wrong with download / extract: #{status}" unless status

        logger.info "Making a symlink so we can use #{lnpath} instead of #{solrpath}"
        lncmd  = "rm -f '#{lnpath}'; ln -s '#{solrpath}' '#{lnpath}'"
        status = system lncmd
        raise "Trouble symlinking #{solrpath} to #{lnpath}" unless status

        logger.info "Storing path to solr directory in dromedary/.solr"
        File.open(DOT_SOLR, 'w:utf-8') do |out|
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

    class Link < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Link in the MED solr configurations to the solr in .solr"


      def call(cmd)

        solr_root       = AnnoyingUtilities.solr_root
        solr_solr_dir   = solr_root + 'server' + 'solr'
        solr_config_dir = solr_solr_dir + 'med'
        solr_lib_dir    = Pathname.new(AnnoyingUtilities.data_dir) + 'lib'

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


    class Start < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Start the solr referenced in .solr"
      argument :rails_env, required: false, default: "development", desc: "The rails environment"


      def solr_bin
        AnnoyingUtilities.solr_root + 'bin' + 'solr'
      end

      def call(rails_env:)
        port    = Solr.get_port_with_logging(rails_env)
        portarg = "-p #{port}"
        command = "#{solr_bin} restart #{portarg} -Dsolr.solr.home=#{AnnoyingUtilities.solr_dir} -Ddromedary.data_dir=\"#{AnnoyingUtilities.data_dir}\""
        logger.info "Starting solr with command:\n  #{command}"
        system command
      end
    end


    class Stop < Start
      argument :rails_env, default: "development", required: false, desc: "The rails environment"

      def call(rails_env:)
        port    = Solr.get_port_with_logging(rails_env)
        portarg = "-p #{port}"
        system "#{solr_bin} stop #{portarg}"
      end
    end

    class Up < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Check to see if solr is up"

      def call(cmd)
        core = AnnoyingUtilities.solr_core

        if core.up?
          logger.info "Solr at #{core.url} appears to be up and running"
        else
          logger.error "Solr core at #{core.url} did not respond (not up?)"
        end

      end
    end


    class Shell < Hanami::CLI::Command

      desc "Get a shell connected to solr, optionally with collections"

      option :entries, required: false, desc: "Path to the entries.json.gz file (exposed as `entry_set`)"
      option :bibs, required: false , desc: "Path to the bib_all.xml (exposed as `bib_set`)"

      def call(entries: nil, bibs: nil, **kw)

        Up.new(command_name: 'shell').call('shell')
        core = AnnoyingUtilities.solr_core

        entry_set = if entries
                      settings = {
                        'med.data_file' => entries
                      }
                      MedInstaller::EntryJsonReader.new(settings)
                    else
                      nil
                    end

        bib_set = if bibs
                    MiddleEnglishDictionary::Collection::BibSet.new(filename: bibs)
                  else
                    nil
                  end

        require 'pry'; binding.pry
      end
    end

  end

end
