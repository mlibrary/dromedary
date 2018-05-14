require_relative 'boot'

require 'rails/all'
require "ettin"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MiddleEnglishDictionary
  class << self
    def config
      @config ||= Ettin.for(Ettin.settings_files("config", Rails.env))
    end
  end
  self.config



  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.autoload_paths << "#{Rails.root}/lib"

    config.relative_url_root = MiddleEnglishDictionary.config.relative_url_root

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
