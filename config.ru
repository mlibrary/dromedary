# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

map MiddleEnglishDictionary::Application.config.relative_url_root || "/" do
  run Rails.application
end
