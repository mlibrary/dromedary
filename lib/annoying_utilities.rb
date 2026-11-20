require "pathname"
require_relative "med_installer/logger"
require_relative "dromedary/services"

# Shared path, logging, and Rails maintenance-mode helpers.
module AnnoyingUtilities
  DROMEDARY_ROOT = Pathname(__dir__).parent.realdirpath

  extend MedInstaller::Logger
  extend self

  def maintenance_mode_flag_file
    Dromedary::Services[:tmp_dir] + "MAINTENANCE_MODE_ENABLED"
  end

  def maintenance_mode_enabled?
    File.exist?(maintenance_mode_flag_file)
  end

  def xslt_dir
    DROMEDARY_ROOT + "indexer" + "xslt"
  end

  def blacklight_solr_url
    Dromedary::Services[:solr_embedded_auth_url]
  end
end
