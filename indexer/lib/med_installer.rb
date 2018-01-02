require 'yell'

module MedInstaller
  LOGGER = Yell.new(STDERR)
end

require 'med_installer/extract'
require 'med_installer/convert'
require 'med_installer/usage'
require 'med_installer/solr'


