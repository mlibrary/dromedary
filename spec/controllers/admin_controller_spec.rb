require 'rails_helper'

RSpec.describe AdminController, type: :controller do

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
