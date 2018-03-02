require 'middle_english_dictionary'
require 'hanami/cli'
require 'annoying_utilities'
require 'simple_solr_client'

require_relative "logger"

Zip.on_exists_proc = true

module MedInstaller
  class Solr
    extend MedInstaller::Logger
    URL         = 'http://mirrors.gigenet.com/apache/lucene/solr/6.6.2/solr-6.6.2.tgz'
    SOLRDIRNAME = 'solr-6.6.2'

    DROMEDARY_ROOT = Pathname(__dir__).parent.parent.realdirpath
    MED_CONFIG     = DROMEDARY_ROOT + 'solr' + 'med'
    SOLR_LIBS      = DROMEDARY_ROOT + 'solr' + 'lib'
    DOT_SOLR       = DROMEDARY_ROOT + '.solr'
    DEFAULT_SOLR   = DROMEDARY_ROOT.parent + 'solr'

    def self.solr_root
      solr_root = if File.exist? DOT_SOLR
                    solr_root = Pathname(File.open(DOT_SOLR).first.chomp)
                    logger.info "Using #{solr_root} from .solr file"
                  else
                    logger.warn "Cannot find #{DOT_SOLR} (should contain path to solr root)"
                    logger.warn "Trying default solr root at #{Solr::DEFAULT_SOLR}"
                    Solr::DEFAULT_SOLR
                  end

      unless Dir.exist? solr_root
        raise "Directory (#{solr_root}) isn't there"
      end
      solr_root
    end

    def self.get_port_with_logging(rails_env)
      p       = AnnoyingUtilities.solr_port(rails_env)
      port    = if p
                  logger.info "Got port #{p} from the solr url in blacklight_config.yml"
                  p
                else
                  logger.warn "Didn't find a port in the url string in blacklight.yml; using 8983"
                  "8983"
                end
      port
    end

    def self.core
      uri      = URI(AnnoyingUtilities.solr_url)
      path     = uri.path.split('/')
      corename = path.pop
      uri.path = path.join('/') # go up a level -- we popped off the core name
      solr_url = uri.to_s

      client = SimpleSolrClient::Client.new(solr_url)
      core   = client.core(corename)
      core
    end



    class Reload < Hanami::CLI::Command
      include  MedInstaller::Logger

      desc "Tell solr to reload the solr config without restarting"

      def call(cmd)
        core = Solr.core

        unless core.up?
          logger.error "Solr core at #{core.url} did not respond (not up?)"
          exit(1)
        end

        core.reload
        logger.info "Core at '#{core.url}' reloaded"

      end
    end


    class Empty < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Delete all documents in the solr"

      def call(cmd)
        core = Solr.core
        unless core.up?
          logger.error "Solr core at #{core.url} did not respond (not up?)"
          exit(1)
        end
        core.clear.commit
        logger.info "Solr core at #{core.url} emptied out"
      end
    end

    class Install < Hanami::CLI::Command
      include  MedInstaller::Logger

      desc "Download and install solr to the given directory"

      argument :installdir, required: true, desc: "The install directory (should be your /path/to/med)"

      def call(installdir:)
        installpath     = Pathname(installdir).realdirpath
        solrpath        = installpath + SOLRDIRNAME
        lnpath          = installpath + 'solr'
        solr_solr_dir   = lnpath + 'server' + 'solr'
        solr_config_dir = solr_solr_dir + 'med'
        solr_lib_dir    = solr_solr_dir + 'lib'

        logger.info "Download/extract from #{URL}"
        status = system(%Q{curl '#{URL}' | tar -C '#{installpath}' -x -z -f -})

        raise "Something went wrong with download / extract" unless status

        logger.info "Making a symlink so we can use #{lnpath} instead of #{solrpath}"
        lncmd  = "rm -f '#{lnpath}'; ln -s '#{solrpath}' '#{lnpath}'"
        status = system lncmd
        raise "Trouble symlinking #{solrpath} to #{lnpath}" unless status

        logger.info "Storing path to solr directory in dromedary/.solr"
        File.open(DOT_SOLR, 'w:utf-8') do |out|
          out.puts lnpath.to_s
        end
        Link.new('solr link').call
      rescue => err
        logger.error err.message
        logger.error "Exiting"
        exit(1)
      end


    end

    class Link < Hanami::CLI::Command
      include  MedInstaller::Logger

      desc "Link in the MED solr configurations to the solr in .solr"


      def call(*args)

        solr_solr_dir   = Solr.solr_root + 'server' + 'solr'
        solr_config_dir = solr_solr_dir + 'med'
        solr_lib_dir    = solr_solr_dir + 'lib'

        logger.info "Linking dromedary solr config stuff into the right spot based on .solr"
        logger.info "Found solr directory #{solr_root}"
        logger.info "Linking  #{Install::MED_CONFIG} into #{solr_config_dir}"
        puts "ln -s '#{Install::MED_CONFIG}' '#{solr_config_dir}'"
        status = system "rm -f '#{solr_config_dir}'; ln -s '#{Install::MED_CONFIG}' '#{solr_config_dir}'"
        raise "Trouble linking #{Install::MED_CONFIG} into the right place in solr" unless status

        logger.info "Linking in #{Install::SOLR_LIBS}"
        status = system "rm -f '#{solr_lib_dir}'; ln -s '#{Install::SOLR_LIBS}' '#{solr_lib_dir}'"
        raise "Trouble linking #{Install::SOLR_LIBS}" unless status
        logger.info "Done"
      rescue => err
        logger.error err.message
        logger.error "Exiting"
        exit(1)
      end

    end


    class Start < Hanami::CLI::Command
      include  MedInstaller::Logger

      desc "Start the solr referenced in .solr"
      option :rails_env, default: "development", desc: "The rails environment"


      def solr_bin
        Solr.solr_root + 'bin' + 'solr'
      end

      def call(rails_env:)
        port = Solr.get_port_with_logging(rails_env)
        portarg = "-p #{port}"
        system "#{solr_bin} restart #{portarg}"
      end
    end


    class Stop < Start
      option :rails_env, default: "development", desc: "The rails environment"

      def call(rails_env:)
        port = Solr.get_port_with_logging(rails_env)
        portarg = "-p #{port}"
        system "#{solr_bin} stop #{portarg}"
      end
    end

  end
end

