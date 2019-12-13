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

    def call(zipfile:)
      build_dir = Pathname.new(Dromedary.config.build_dir).realdirpath
      build_dir.mkpath

      xmldir = build_dir + 'xml'
      xmldir.mkpath

      # Ugh. Need to fix this so it's not so stupid. AnnoyingUtilities
      # are too hard-coded. And hence annoying!

      original_data_dir = AnnoyingUtilities.data_dir
      AnnoyingUtilities.data_dir = build_dir

      logger.info "Begin extraction from #{zipfile}"
      MedInstaller::Extract.new.call(zipfile: zipfile, datadir: build_dir)
      logger.info "...done"


      logger.info "Begin conversion of data in #{xmldir}"
      MedInstaller::Convert.new(command_name: 'convert').call(source_dir: xmldir)
      logger.info "...done"
      logger.info "Data now ready for /bin/dromedary index_new_data"
    end




  end
end
