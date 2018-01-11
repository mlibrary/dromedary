require 'yell'

module MedInstaller
  LOGGER = Yell.new(STDERR)
end

require_relative 'med_installer/extract'
require_relative 'med_installer/convert'
require_relative 'med_installer/usage'
require_relative 'med_installer/solr'


