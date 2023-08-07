# frozen_string_literal: true

require "canister"
require "date"
module MedInstaller
  Services = Canister.new
  Services.register(:root_directory) { Pathname(__dir__).parent.realdirpath }
  Services.register(:data_directory) { ENV["DATA_DIRECTORY"] || (Services[:root_directory] + "data").to_s }
  Services.register(:build_directory) do
    yyyymmdd = Date.today.strftime("%Y%m%d")
    default_filename = "build_#{yyyymmdd}"
    ENV["BUILD_DIRECTORY"] || (Pathname.new(Services[:data_directory]) + default_filename).to_s
  end
end
