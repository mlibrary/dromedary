# This file is used by Rack-based servers to start the application.

require_relative "config/environment"


run Rails.application
# this is in the routes now
# map Dromedary.config.relative_url_root || "/" do
#   run Rails.application
# end
