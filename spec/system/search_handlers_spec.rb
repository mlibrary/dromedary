# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Search handlers", type: :system do
  describe "dictionary search" do
    it "returns results for headword search" do
      visit "/dictionary?q=abissus&search_field=hnf"
      expect(page.status_code).to eq 200
      expect(page).to have_css(".document")
    end

    it "returns results for entire entry search" do
      visit "/dictionary?q=women&search_field=anywhere"
      expect(page.status_code).to eq 200
      expect(page).to have_css(".document")
    end

    it "returns results for headword-only search" do
      visit "/dictionary?q=abissus&search_field=h"
      expect(page.status_code).to eq 200
      expect(page).to have_css(".document")
    end

    it "returns results for citation search" do
      visit "/dictionary?q=love&search_field=citation"
      expect(page.status_code).to eq 200
      expect(page).to have_css(".document")
    end
  end

  describe "bibliography search" do
    it "returns results for entire entry search" do
      visit "/bibliography?q=women&search_field=bib_keyword"
      expect(page.status_code).to eq 200
      expect(page).to have_css(".document")
    end

    it "returns results for author/title search" do
      visit "/bibliography?q=chaucer&search_field=bib_author_title"
      expect(page.status_code).to eq 200
      expect(page).to have_css(".document")
    end

    it "returns results for external references search" do
      visit "/bibliography?q=1162&search_field=bib_external_references"
      expect(page.status_code).to eq 200
      expect(page).to have_css(".document")
    end
  end

  describe "quotations search" do
    it "returns results for quote everything search" do
      visit "/quotations?q=love&search_field=quote_everything"
      expect(page.status_code).to eq 200
      expect(page).to have_css(".document")
    end

    it "returns results for quote text only search" do
      visit "/quotations?q=love&search_field=quote_quote"
      expect(page.status_code).to eq 200
      expect(page).to have_css(".document")
    end
  end
end
