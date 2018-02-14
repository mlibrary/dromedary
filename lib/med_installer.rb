require 'semantic_logger'
require 'middle_english_dictionary'

module MedInstaller
  SemanticLogger.add_appender(io: STDERR, level: :info)
  LOGGER = SemanticLogger['Entry']
end

require_relative 'med_installer/extract'
require_relative 'med_installer/convert'
require_relative 'med_installer/usage'
require_relative 'med_installer/solr'


