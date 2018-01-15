require_relative '../dromedary/entry'
require 'hanami/cli'

Zip.on_exists_proc = true

module MedInstaller
  class Solr
    URL         = 'http://mirrors.gigenet.com/apache/lucene/solr/6.6.2/solr-6.6.2.tgz'
    SOLRDIRNAME = 'solr-6.6.2'

    DROMEDARY_ROOT = Pathname(__dir__).parent.parent
    MED_CONFIG     = DROMEDARY_ROOT + 'solr' + 'med'
    SOLR_LIBS      = DROMEDARY_ROOT + 'solr' + 'lib'
    DOT_SOLR       = DROMEDARY_ROOT + '.solr'


    class Install < Hanami::CLI::Command
      desc "Download and install solr to the given directory"

      argument :installdir, required: true, desc: "The install directory (should be your /path/to/med)"


      def logger
        MedInstaller::LOGGER
      end

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

        logger.info "Storing solr installation information in dromedary/.solr"
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

      desc "Link in the MED solr configurations to the solr in .solr"

      def logger
        MedInstaller::LOGGER
      end

      def solr_root
        unless File.exist? DOT_SOLR
          raise "Cannot find #{DOT_SOLR} (should contain path to solr root)"
        end

        solr_root = Pathname(File.open(DOT_SOLR).first.chomp)
        unless Dir.exist? solr_root
          raise "Found .solr, but doesn't seem to point to solr root (#{solr_root})"
        end

        solr_root
      end

      def call(*args)

        solr_solr_dir   = solr_root + 'server' + 'solr'
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

      desc "Start the solr referenced in .solr"
      option :port, default: 8983, desc: "The port solr should run on"

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

      def call(port:)
        portarg = "-p #{port}"
        system "#{solr_bin} restart #{portarg}"
      end
    end


    class Stop < Start
      option :port, default: 8983, desc: "The port solr is running on"
      def call(port:)
        portarg = "-p #{port}"
        system "#{solr_bin} stop #{portarg}"
      end
    end

  end
end

