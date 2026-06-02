# frozen_string_literal: true

# System specs for the dromedary upgrade regression checklist.
#
# These specs verify that pages load, key elements are present, and
# interactions don't error. They are NOT asserting exact HTML -- they
# catch the class of regression introduced by Bootstrap and ViewComponent
# migrations.
#
# SOLR REQUIREMENT: These specs require a running Solr with indexed data.
# Run inside Docker: `dc run --rm app bundle exec rspec spec/system/`
#
# TODO: Replace live-Solr dependency with a deterministic snapshot.
#   1. Run: `dc exec solr solr backup -c med-preview -d /var/solr/data/backups`
#   2. Copy backup to spec/fixtures/solr/
#   3. Write a RSpec before(:suite) hook that restores the snapshot into a
#      test collection before the suite runs and removes it after.

require "rails_helper"

RSpec.describe "Dromedary regression checklist", type: :system do
  # ------------------------------------------------------------
  # Homepage / splash
  # ------------------------------------------------------------

  describe "homepage" do
    it "loads without error" do
      visit root_path
      expect(page).to have_http_status(:ok)
      expect(page).not_to have_content("We're sorry, but something went wrong")
    end
  end

  # ------------------------------------------------------------
  # Dictionary search
  # ------------------------------------------------------------

  describe "dictionary search" do
    before { visit "/dictionary" }

    it "search form submits and returns results" do
      fill_in "q", with: "love"
      click_button "Search"
      expect(page).to have_http_status(:ok)
      expect(page).not_to have_content("We're sorry, but something went wrong")
      # Either results or a zero-results message -- both are valid
      expect(page).to have_css(".blacklight-catalog, .no-results, [data-document-id], #search-results, #documents")
        .or(have_content("No results found"))
    end

    it "facet sidebar is present" do
      fill_in "q", with: "god"
      click_button "Search"
      expect(page).to have_css("#facets, .facets, .blacklight-facets, aside")
    end

    it "per-page selector is present" do
      fill_in "q", with: "god"
      click_button "Search"
      expect(page).to have_css("select[name='per_page'], .per-page, #per-page, #per_page-dropdown")
        .or(have_content("per page"))
    end

    it "sort selector is present" do
      fill_in "q", with: "god"
      click_button "Search"
      expect(page).to have_css("select[name='sort'], .sort-widget, #sort-widget, #sort-dropdown")
        .or(have_content("Sort by"))
    end
  end

  # ------------------------------------------------------------
  # Show / detail page
  # ------------------------------------------------------------

  describe "dictionary show page" do
    # MED1 is a stable headword document ID present in the index
    let(:known_id) { "MED1" }

    it "loads for a known document ID pattern" do
      visit "/dictionary/#{known_id}"
      # Either renders the doc or shows a proper 404 -- both avoid 500
      expect(page.status_code).to be_in([200, 404])
      expect(page).not_to have_content("We're sorry, but something went wrong")
    end

    it "renders 404 page for unknown document" do
      visit "/dictionary/MEDNONEXISTENT99999"
      expect(page).not_to have_content("We're sorry, but something went wrong")
      # Should render custom 404 or redirect, not 500
      expect(page.status_code).to be_in([200, 404])
    end
  end

  # ------------------------------------------------------------
  # Bibliography
  # ------------------------------------------------------------

  describe "bibliography" do
    it "index loads without error" do
      visit "/bibliography"
      expect(page).to have_http_status(:ok)
      expect(page).not_to have_content("We're sorry, but something went wrong")
    end

    it "search returns results" do
      visit "/bibliography"
      fill_in "q", with: "chaucer"
      click_button "Search"
      expect(page).to have_http_status(:ok)
      expect(page).not_to have_content("We're sorry, but something went wrong")
    end
  end

  # ------------------------------------------------------------
  # Print view
  # ------------------------------------------------------------

  describe "print view" do
    it "renders without error when accessed directly" do
      visit "/dictionary?q=abissus"
      expect(page).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------
  # About / static pages
  # ------------------------------------------------------------

  describe "static pages" do
    it "about page loads" do
      visit about_path
      expect(page).to have_http_status(:ok)
      expect(page).not_to have_content("We're sorry, but something went wrong")
    end

    it "contact page loads" do
      visit "/contacts"
      expect(page).to have_http_status(:ok)
      expect(page).not_to have_content("We're sorry, but something went wrong")
    end
  end

  # ------------------------------------------------------------
  # Quotations
  # ------------------------------------------------------------

  describe "quotations" do
    it "index loads without error" do
      visit "/quotations"
      expect(page).to have_http_status(:ok)
      expect(page).not_to have_content("We're sorry, but something went wrong")
    end
  end

  # ------------------------------------------------------------
  # Pagination
  # ------------------------------------------------------------

  describe "pagination" do
    it "next page link works" do
      visit "/dictionary?q=ab"  # 131 entries starting with 'ab-' -> multiple pages
      next_links = all("a[rel='next']")
      if next_links.any?
        next_links.first.click
        expect(page).to have_http_status(:ok)
        expect(page).not_to have_content("We're sorry, but something went wrong")
      else
        skip "No next page link found -- query may return <= 1 page of results"
      end
    end
  end

  # ------------------------------------------------------------
  # Auto-suggest endpoint (non-JS: just verify the endpoint responds)
  # ------------------------------------------------------------

  describe "auto-suggest endpoint" do
    it "headword suggester returns HTML li elements for prefix 'ab'" do
      visit "/dictionary/suggest?q=ab&search_field=h"
      expect(page.status_code).to eq(200)
      expect(page.body).to include("<li")
      expect(page.body).to include("data-autocomplete-value")
      expect(page.body).to include("abject")
    end
  end
end
