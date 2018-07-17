require_relative 'boot'

require 'rails/all'
require 'json'
require_relative "load_local_config"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dromedary
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.autoload_paths << "#{Rails.root}/lib"
    config.autoload_paths << "#{Rails.root}/app/presenters"

    config.relative_url_root = Dromedary.config.relative_url_root
    config.action_controller.relative_url_root = config.relative_url_root

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end


  def self.hyp_to_bibid
    target = Pathname.new(Dromedary.data_dir) + 'hyp_to_bibid.json'
    @hyp_to_bibid ||= JSON.load(File.open(target))
  end

end
