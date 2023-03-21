require "rails_helper"

class CommonPresenter
  include Rails.application.routes.url_helpers
  include CommonPresenters
end

RSpec.describe CommonPresenters do
  let(:presenter) { CommonPresenter.new }

  describe "#first_found_value_as_highlithed_array" do
    let(:document) { instance_double(SolrDocument, "document") }
    let(:list_of_fieldnames) { [] }
    let(:default) { [] }

    it { expect(presenter.first_found_value_as_highlighted_array(document, list_of_fieldnames, default)).to eq [] }
  end

  describe "#hl_field" do
    let(:document) { instance_double(SolrDocument, "document") }
    let(:has_highlight_field) { false }
    let(:has_field) { false }
    let(:k) { nil }

    before do
      allow(document).to receive(:has_highlight_field?).with(k).and_return(has_highlight_field)
      allow(document).to receive(:has_field?).with(k).and_return(has_field)
    end

    it { expect(presenter.hl_field(document, k)).to eq [] }
  end
end
