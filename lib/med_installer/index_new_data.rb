require_relative "index"
require_relative "control"
require_relative "copy_from_build"
require_relative "../../config/load_local_config"

module MedInstaller
  # Copy the already-munged files from the build directory into this
  # instances data_dir, presumably for later indexing.
  class IndexNewData < Hanami::CLI::Command
    include MedInstaller::Logger

    option :build_directory,
      required: false,
      default: Services[:build_directory],
      desc: "The build directory with entries.json.gz and hyp_to_bibid.json"
    
    def call(force:)
      MedInstaller::Index::Full.new(command_name: "index full").call(debug: false, existing_hyp_to_bibid: false)
    end
  end
end
