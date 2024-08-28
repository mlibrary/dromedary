# frozen_string_literal: true

require_relative "../dromedary/services"
require_relative "extract"
require_relative "convert"

module MedInstaller
  # Convert a MED zipfile into something we can index
  class Prepare < Hanami::CLI::Command
    include MedInstaller::Logger

    desc "Extract/convert data from a zipfile"
    argument :zipfile,
      required: true,
      desc: "Zipfile which contains all the MED data"

    option :build_directory,
      required: false,
      default: Dromedary::Services[:build_directory],
      desc: "The build directory. XML files will be extracted to <build_directory>/xml"

    def call(zipfile:, build_directory:)
      logger.info "Beginning extraction of data from #{zipfile} into #{build_directory}"
      Extract.new(command_name: "extract").call(zipfile: zipfile, build_directory: build_directory)

      logger.info "Converting raw data in #{build_directory} to entries.json.gz"
      Convert.new(command_name: "convert").call(build_directory: build_directory)
    end
  end
end
