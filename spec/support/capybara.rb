# frozen_string_literal: true

require "capybara/rails"
require "capybara/rspec"

# Default driver: rack_test (fast, no JS, no browser needed)
# Use `js: true` or `driver: :selenium_chrome_headless` for JS tests
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_headless

# Allow connections to Solr running in Docker
Capybara.server_host = "0.0.0.0"

RSpec.configure do |config|
  config.include Capybara::DSL, type: :system
  config.include Capybara::RSpecMatchers, type: :system

  # Default to rack_test (no browser needed) for all system specs.
  # Use `before { driven_by :selenium_chrome_headless }` in a specific spec for JS.
  config.before(:each, type: :system) do
    driven_by :rack_test
  end
end
