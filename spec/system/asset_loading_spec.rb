# frozen_string_literal: true

# Phase 0: Verify foundation assets load correctly.
#
# These tests assert that:
#   1. The SCSS import path uses 'blacklight/blacklight' (not 'blacklight-frontend/...')
#   2. rails-ujs is not referenced in application.js (deprecated in Rails 7+)
#
# SOLR REQUIREMENT: Requires a running Solr with indexed data.

require "rails_helper"

RSpec.describe "Asset loading", type: :system do
  describe "blacklight stylesheet import" do
    it "does not reference blacklight-frontend/stylesheets path" do
      content = File.read(Rails.root.join("app/assets/stylesheets/blacklight.scss"))
      expect(content).not_to include("blacklight-frontend/stylesheets"),
        "blacklight.scss still uses the old 'blacklight-frontend/stylesheets' import path"
    end

    it "imports blacklight/blacklight for Sprockets" do
      content = File.read(Rails.root.join("app/assets/stylesheets/blacklight.scss"))
      expect(content).to include("blacklight/blacklight"),
        "blacklight.scss should import 'blacklight/blacklight' for Sprockets"
    end
  end

  describe "application.js" do
    it "does not require rails-ujs" do
      content = File.read(Rails.root.join("app/assets/javascripts/application.js"))
      expect(content).not_to match(/require\s+rails-ujs/),
        "application.js still requires rails-ujs (deprecated in Rails 7+)"
    end
  end

  describe "page loads without asset errors" do
    it "returns 200 on the home page" do
      visit "/"
      expect(page.status_code).to eq 200
    end

    it "does not reference blacklight-frontend in rendered HTML" do
      visit "/"
      expect(page.html).not_to include("blacklight-frontend/stylesheets")
    end
  end
end
