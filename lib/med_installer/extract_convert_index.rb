require_relative 'extract'
require_relative 'convert'
require_relative 'index'
require_relative 'control'

require 'fileutils'

require_relative 'job_monitoring'

require_relative '../../config/load_local_config'

module MedInstaller

  # Start from a zip file and go from there
  class ExtractConvertIndex < Hanami::CLI::Command
    include MedInstaller::Logger

    argument :zipfile, required: true, desc: "The path to the zipfile (downloaded from Box)"

    def call(zipfile:)
      # metrics = MiddleEnglishIndexMetrics.new({type: "extract_convert_index_data"})
      build_dir = Pathname.new(Dromedary.config.build_dir).realdirpath
      build_dir.mkpath

      xmldir = build_dir + 'xml'
      xmldir.mkpath

      # Ugh. Need to fix this so it's not so stupid. AnnoyingUtilities
      # are too hard-coded. And hence annoying!

      original_data_dir = AnnoyingUtilities.data_dir
      AnnoyingUtilities.data_dir = build_dir

      logger.info "Begin extraction from #{zipfile}"
      MedInstaller::Extract.new(command_name: "extract").call(zipfile: zipfile, datadir: build_dir)
      logger.info "...done"


      logger.info "Begin conversion of data in #{xmldir}"
      MedInstaller::Convert.new(command_name: 'convert').call(source_dir: build_dir + 'xml' )
      logger.info "...done"

      logger.info "Setting to maintenance mode during indexing"
      MedInstaller::Control::MaintenanceModeOn.new(command_name: 'maintenance_mode on').call('on')

      logger.info "Copying bib_all.xml to build dir #{build_dir}"
      %w[bib_all.xml].each do |f|
        path = xmldir + f
        FileUtils.copy path, build_dir
      end

      logger.info "Begin full index"
      MedInstaller::Index::Full.new(command_name: "index full").call(debug: false, existing_hyp_to_bibid: false)
      logger.info "...done"

      logger.info "Copying files to live site"
      %w[entries.json.gz bib_all.xml hyp_to_bibid.json].each do |f|
        path = build_dir + f
        if ! path.exist?
          logger.warn "File #{path} not found, can't be copied to #{original_data_dir}"
        end
        FileUtils.copy path, original_data_dir
      end

      logger.info "New data in place. Making the site live again."
      MedInstaller::Control::MaintenanceModeOff.new(command_name: 'maintenance_mode off').call('off')
      # metrics.log_success
    end




  end
end
