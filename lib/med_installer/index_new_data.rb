require_relative "index"
require_relative "control"
require_relative "copy_from_build"
require_relative "../../config/load_local_config"

module MedInstaller
  # Copy the already-munged files from the build directory into this
  # instances data_dir, presumably for later indexing.
  class IndexNewData < Hanami::CLI::Command
    include MedInstaller::Logger

    option :force,
      required: false,
      default: false,
      values: %w[true false],
      desc: "Force indexing even if the files in build aren't newer than those currently in this instance's data_dir"

    def call(force:)
      MedInstaller::CopyFromBuild.new(command_name: "copy_from_build").call(force: force)
      MedInstaller::Index::Full.new(command_name: "index full").call(debug: false, existing_hyp_to_bibid: false)
    end
  end
end
