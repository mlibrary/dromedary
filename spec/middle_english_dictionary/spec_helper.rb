require_relative "spec_helper"
require "bundler/setup"
require "middle_english_dictionary"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require "pathname"
SPEC_DATA = Pathname.new(__dir__) + "data"
