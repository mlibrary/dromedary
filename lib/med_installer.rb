require 'semantic_logger'
require 'middle_english_dictionary'


require_relative 'med_installer/logger'
require_relative 'med_installer/extract'
require_relative 'med_installer/index'
require_relative 'med_installer/convert'
require_relative 'med_installer/solr'
require_relative 'med_installer/indexer/entry_json_reader'
require_relative 'med_installer/indexer/bib_reader'
require_relative 'med_installer/index'
require_relative 'med_installer/extract_convert_index'

require_relative 'med_installer/remote'
require_relative 'med_installer/control'

require_relative 'med_installer/copy_from_build'
require_relative 'med_installer/prepare_new_data'
require_relative 'med_installer/index_new_data'

require_relative 'med_installer/ping_prometheus'