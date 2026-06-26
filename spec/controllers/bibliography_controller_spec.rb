require "rails_helper"

RSpec.describe BibliographyController, type: :controller do
  describe "GET #index" do
    # Requires live Solr connection; covered by spec/system/search_spec.rb:106
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show", pending: "review" do
    it "returns http success" do
      get :show
      expect(response).to have_http_status(:success)
    end
  end
end
