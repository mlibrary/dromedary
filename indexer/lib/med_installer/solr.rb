require 'dromedary/entry'
require 'hanami/cli'

Zip.on_exists_proc = true

module MedInstaller
  class Solr
    class Install < Hanami::CLI::Command
      desc "Download and install solr to the given directory"

      argument :installdir, required: true, desc: "The install directory (should be your /path/to/med)"


      def logger
        MedInstaller::LOGGER
      end

      URL         = 'http://mirrors.gigenet.com/apache/lucene/solr/6.6.2/solr-6.6.2.tgz'
      SOLRDIRNAME = 'solr-6.6.2'

      DROMEDARY_ROOT = Pathname(__dir__).parent.parent.parent
      MED_CONFIG     = DROMEDARY_ROOT + 'solr' + 'med'
      DOT_SOLR       = DROMEDARY_ROOT + '.solr'

      def call(installdir:)
        installpath     = Pathname(installdir).realdirpath
        solrpath        = installpath + SOLRDIRNAME
        lnpath          = installpath + 'solr'
        solr_config_dir = lnpath + 'server' + 'solr' + 'med'

        logger.info "Download/extract from #{URL}"
        # status = system(%Q{curl '#{URL}' | tar -C '#{installpath}' -x -z -f -})
        #
        # raise "Something went wrong with download / extract" unless status

        logger.info "Making a symlink so we can use #{lnpath} instead of #{solrpath}"
        lncmd  = "rm -f '#{lnpath}'; ln -s '#{solrpath}' '#{lnpath}'"
        status = system lncmd
        raise "Trouble symlinking #{solrpath} to #{lnpath}" unless status

        logger.info "Linking dromedary solr config into the right spot"
        status = system "rm -f '#{solr_config_dir}'; ln -s '#{MED_CONFIG}' '#{solr_config_dir}'"
        raise "Trouble linking #{MED_CONFIG} into the right place in solr" unless status
        logger.info "Storing solr installation information in dromedary/.solr"
        File.open(DOT_SOLR, 'w:utf-8') do |out|
          out.puts lnpath.to_s
        end
      rescue => err
        logger.error err.message
        logger.error "Exiting"
        exit(1)
      end


    end
    class Start < Hanami::CLI::Command
      DROMEDARY_ROOT = Pathname(__dir__).parent.parent.parent
      DOT_SOLR       = DROMEDARY_ROOT + '.solr'

      def logger
        MedInstaller::LOGGER
      end

      def solr_bin
        unless File.exist? DOT_SOLR
          raise "Cannot find #{DOT_SOLR} (should contain path to solr root)"
        end

        solr_root = Pathname(File.open(DOT_SOLR).first.chomp)
        unless Dir.exist? solr_root
          raise "Found .solr, but doesn't seem to point to solr root (#{solr_root})"
        end

        solr_bin = solr_root + 'bin' + 'solr'
      rescue => err
        logger.error err.message
        exit(1)
      end

      def call(*args)
        system "#{solr_bin} restart"
      end
    end


    class Stop < Start
      def call(*args)
        system "#{solr_bin} stop"
      end
    end

  end
end

