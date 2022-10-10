require_relative 'boot'

require 'rails/all'
require 'json'
require_relative "load_local_config"
require 'json'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# JSON_FORMATTER = ->(log, logger) do
#   h               = log.to_h(logger.host)
#   h[:application] = 'MED'
#   if h[:named_tags]
#     h[:ip] = h[:named_tags].delete(:ip) if h[:named_tags].has_key?(:ip)
#     h.delete(:named_tags) if h[:named_tags].empty?
#   end
#
#   h[:payload] && h[:payload][:params] && h[:payload][:params].delete('utf8')
#
#   h.to_json
# end

module Dromedary
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.autoload_paths << "#{Rails.root}/lib"
    config.autoload_paths << "#{Rails.root}/app/presenters"

    config.log_level = :info

    config.lograge.enabled = true

    # add time to lograge
    config.lograge.custom_options = lambda do |event|
      {time: event.time}
    end

    config.lograge.custom_payload do |controller|
      {
        host:  controller.request.host,
        ip:    controller.request.ip,
        query: controller.request.query_parameters
      }
    end

    config.lograge.formatter = Lograge::Formatters::Json.new

    config.active_job.queue_adapter = :sidekiq


    # config.log_tags = {
    #   ip:         :remote_ip,
    # }
    # config.rails_semantic_logger.quiet_assets = true
    # config.rails_semantic_logger.format = :json

    # config.rails_semantic_logger.add_file_appender = false
    # config.semantic_logger.add_appender(file_name: "log/#{Rails.env}.log", level: :info)
    # config.semantic_logger.add_appender(file_name: "log/#{Rails.env}.json", formatter: JSON_FORMATTER, level: :info)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end

end
