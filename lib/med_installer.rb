# Top-level namespace and entry point for the MED (Middle English Dictionary)
# installer tooling.
#
# Requiring this file loads all installer sub-modules including:
# * CLI commands for extracting, converting, and indexing MED data
# * Solr administration helpers
# * Prometheus metrics ping support
# * Remote deployment helpers (see {MedInstaller::Remote})
#
# The installer commands are registered with the Hanami CLI in +bin/dromedary+.
require "semantic_logger"
require "middle_english_dictionary"

require_relative "med_installer/logger"
require_relative "med_installer/extract"
require_relative "med_installer/index"
require_relative "med_installer/convert"
require_relative "med_installer/solr"
require_relative "med_installer/indexer/entry_json_reader"
require_relative "med_installer/indexer/bib_reader"
require_relative "med_installer/extract_convert_index"

require_relative "med_installer/remote"
require_relative "med_installer/control"

require_relative "med_installer/copy_from_build"
require_relative "med_installer/index_new_data"

require_relative "med_installer/ping_prometheus"
