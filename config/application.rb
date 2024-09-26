require_relative "boot"
require "rails/all"
require "json"
require_relative "../lib/dromedary/services"
require_relative "../lib/dromedary/abbreviated_json_format"

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

    # CORS with rails running not-at-the-root turns out to be mostly broken.
    # So we do this, which stinks.
    config.action_controller.forgery_protection_origin_check = false

    config.time_zone = 'Eastern Time (US & Canada)'

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.autoload_paths << "#{Rails.root}/lib"
    config.autoload_paths << "#{Rails.root}/app/presenters"

    config.relative_url_root = Dromedary::Services[:relative_url_root]
    config.action_controller.relative_url_root = config.relative_url_root
    # config.assets.prefix = Dromedary::Services[:relative_url_root]
    # config.relative_url_root                   = '/'
    # config.action_controller.relative_url_root = '/'

    config.blacklight_url = Dromedary::Services[:solr_embedded_auth_url]

    config.log_level = :info
    config.rails_semantic_logger.add_file_appender = false
    config.semantic_logger.backtrace_level = :error
    config.log_tags = {
      ip: :remote_ip
    }
    # Just use the standard :json logger and worry about filtering on the receiving end
    # config.rails_semantic_logger.format = Dromedary::AbbreviatedJsonFormat.new
    config.rails_semantic_logger.format = :json
    config.semantic_logger.add_appender(io: $stdout)

    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess]

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

    # Done with all that? Now pull in local Ettin-based configuration.

    require_relative "load_local_config"
  end
end
