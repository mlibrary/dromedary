# frozen_string_literal: true

require "canister"
module MedInstaller
  
  Services = Canister.new
  Services.register(:data_directory) { ENV["DATA_DIRECTORY"] }
  
  
end
