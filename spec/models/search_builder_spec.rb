require "rails_helper"

RSpec.describe SearchBuilder do
  let(:user_params) { {} }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:scope) { double blacklight_config: blacklight_config }
  subject(:search_builder) { described_class.new scope }
end
