require_relative 'extract'
require_relative 'convert'
require_relative 'index'
require_relative 'control'

require 'fileutils'

require_relative '../../config/load_local_config'

module MedInstaller

  # Start from a zip file and go from there
  class PrepareNewData < Hanami::CLI::Command
    include MedInstaller::Logger

    argument :zipfile, required: true, desc: "The path to the zipfile (downloaded from Box). Must be on the server where the instance is running."

    class YabedaHelper

      attr_accessor :start_time, :enabled

      def new
        @enabled = false
        if ENV['PROMETHEUS_GATEWAY']
          @enabled = true
        end
      end

      def configure!
        if enabled
          Yabeda.configure do
            group :prepare_data do
              gauge :duration_seconds, comment: "Time spent running prepare_data"
              gauge :last_success, comment: "Last successful run of prepare_data"
              gauge :last_failure, tags: :err_msg, comment: "Last failed run of prepare_data"
            end
          end

          @start_time = Time.now
          Yabeda.configure!
        end
      end

      def log_success
        if enabled
          Yabeda.prepare_data.duration_seconds.set({}, Time.now - @start_time)
          Yabeda.prepare_data.last_success.set({}, Time.now.to_i)
          Yabeda::Prometheus.push_gateway.add(Yabeda::Prometheus.registry)
        end
      end

      def log_failure(err)
        if enabled
          Yabeda.prepare_data.last_failure.set({err_msg: err}, Time.now.to_i)
          Yabeda::Prometheus.push_gateway.add(Yabeda::Prometheus.registry)
        end
      end

    end


    def call(zipfile:)
      begin
        helper = YabedaHelper.new
        helper.configure!

        build_dir = Pathname.new(Dromedary.config.build_dir).realdirpath
        build_dir.mkpath

        xmldir = build_dir + 'xml'
        xmldir.mkpath

        ## Ugh. Need to fix this so it's not so stupid. AnnoyingUtilities
        ## are too hard-coded. And hence annoying!
        #
        original_data_dir = AnnoyingUtilities.data_dir
        AnnoyingUtilities.data_dir = build_dir

        logger.info "Begin extraction from #{zipfile}"
        MedInstaller::Extract.new(command_name: "extract").call(zipfile: zipfile, datadir: build_dir)
        logger.info "...done"


        logger.info "Begin conversion of data in #{xmldir}"
        MedInstaller::Convert.new(command_name: 'convert').call(source_dir: xmldir)
        logger.info "...done"

        logger.info "Creating hyp_to_bibid file in build directory"
        mapping = hyp_to_bibid(xmldir + "bib_all.xml")
        File.open(xmldir + "hyp_to_bibid.json", 'w:utf-8') do |out|
          out.puts mapping.to_json
        end

        # Finally, copy the files to the root of the build directory
        logger.info "Putting newly-prepared files in build directory"
        %w[bib_all.xml hyp_to_bibid.json].each do |f|
          path = xmldir + f
          FileUtils.copy path, build_dir
        end
        logger.info "Data now ready for /bin/dromedary newdata index_new_data"
        helper.log_success
      rescue err
        helper.log_failure(err)
        raise err
      end
    end


    def bibset(filename)
      @bibset ||= MiddleEnglishDictionary::Collection::BibSet.new(filename: filename)
    end

    def hyp_to_bibid(bib_all_xml_path)
      logger.info "Building hyp_to_bibid mapping"
      @hyp_to_bibid ||= bibset(bib_all_xml_path).reduce({}) do |acc, bib|
        bib.hyps.each do |hyp|
          acc[hyp.gsub('\\', '').upcase] = bib.id # TODO: Take out when backslashes removed from HYP ids
        end
        acc
      end
    end



  end
end
