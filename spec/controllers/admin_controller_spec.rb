require "rails_helper"

RSpec.describe AdminController, type: :controller do
  let(:fake_collections) do
    instance_double(
      MedSolrCollections,
      collections: [],
      each_with_index: [],
      each: [],
      released?: false,
      preview: nil,
      production: nil,
      nothing_there?: true,
      force_release_candidates: [],
      current_runner: nil
    ).tap do |dbl|
      allow(dbl).to receive(:each).and_yield
      allow(dbl).to receive(:each_with_index).and_yield(nil, 0)
      allow(dbl).to receive(:each_with_index).with(no_args).and_return([])
    end
  end

  before do
    allow(MedSolrCollections).to receive(:new).and_return(fake_collections)
  end

  describe "GET #home" do
    it "returns http success" do
      get :home
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #release" do
    it "returns http success" do
      get :release
      expect(response).to have_http_status(:success)
    end
  end
end
