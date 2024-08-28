require_relative "index"
require_relative "control"
require_relative "copy_from_build"
require_relative "../dromedary/services"
module MedInstaller

  class IndexNewData < Hanami::CLI::Command
    include MedInstaller::Logger

    option :build_directory,
      required: false,
      default: Dromedary::Services[:build_directory],
      desc: "The build directory with entries.json.gz and hyp_to_bibid.json"

    def call(build_directory:)
      MedInstaller::Index::Full.new(command_name: "index full").call(debug: false, existing_hyp_to_bibid: false, build_directory: build_directory)
    end
  end
end
