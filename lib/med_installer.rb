require 'semantic_logger'
require_relative 'dromedary/entry'


module MedInstaller
  LOGGER = Dromedary::Entry::Constants::LOGGER
end

require_relative 'med_installer/extract'
require_relative 'med_installer/convert'
require_relative 'med_installer/usage'
require_relative 'med_installer/solr'


