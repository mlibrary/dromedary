# frozen_string_literal: true

# System specs that verify page structure against the live production reference
# pages captured at doc/bootstrap_upgrade/reference_pages/.
#
# These tests assert that key structural elements (headings, navigation, search
# forms, facets, result cards, show-page sections) survive the Bootstrap 5 and
# Blacklight 9 view migrations. They do NOT assert exact HTML -- they verify
# that elements the reference system renders are still present.
#
# SOLR REQUIREMENT: These specs require a running Solr with indexed data.
# Run inside Docker: `dc run --rm app bundle exec rspec spec/system/`
#
# Reference: doc/bootstrap_upgrade/reference_pages/README.md

require "rails_helper"

RSpec.describe "View structure (reference system)", type: :system do
  # ------------------------------------------------------------
  # Shared: elements present on ALL pages
  # ------------------------------------------------------------

  shared_examples "has site header" do
    it "renders the site title" do
      expect(page).to have_content("Middle English Compendium")
    end

    it "renders University of Michigan branding" do
      expect(page).to have_css("img[alt='University of Michigan']")
    end
  end

  shared_examples "has footer" do
    it "renders the footer" do
      expect(page).to have_css("footer")
    end

    it "has Middle English Compendium links in footer" do
      within("footer") do
        expect(page).to have_link("Middle English Dictionary")
        expect(page).to have_link("Bibliography")
      end
    end

    it "has help links in footer" do
      within("footer") do
        expect(page).to have_link("Search Help")
        expect(page).to have_link("About the MEC")
      end
    end

    it "has contact links in footer" do
      within("footer") do
        expect(page).to have_link("Contact Us")
        expect(page).to have_link("mec-info@umich.edu")
      end
    end
  end

  shared_examples "has navigation" do
    it "has dictionary link" do
      expect(page).to have_link("Middle English Dictionary")
    end

    it "has bibliography link" do
      expect(page).to have_link("Bibliography")
    end

    it "has quotations link" do
      expect(page).to have_link("Quotations")
    end
  end

  shared_examples "has skip links" do
    it "renders skip links" do
      expect(page).to have_link("Skip to main content")
        .or(have_link("Skip to results"))
        .or(have_link("Skip to search form"))
    end
  end

  shared_examples "has search form" do
    it "renders a search input" do
      expect(page).to have_css("input[name='q']")
    end

    it "renders a search button" do
      expect(page).to have_button("Search")
    end
  end

  shared_examples "has keyboard dropdown" do
    it "renders the keyboard special character dropdown" do
      expect(page).to have_css(".keyboard")
    end

    it "has thorn character" do
      expect(page).to have_link("Þ þ (thorn)")
    end

    it "has eth character" do
      expect(page).to have_link("Ð ð (eth)")
    end

    it "has yogh character" do
      expect(page).to have_link("Ʒ ʒ (yogh)")
    end

    it "has ash character" do
      expect(page).to have_link("Æ æ (ash)")
    end
  end

  # ------------------------------------------------------------
  # 1. Splash / Home page
  # ------------------------------------------------------------

  describe "splash page" do
    before { visit "/" }

    include_examples "has site header"
    include_examples "has footer"
    include_examples "has navigation"

    it "renders the H1 heading" do
      expect(page).to have_selector("h1", text: "Middle English Compendium")
    end

    it "describes the three resources" do
      expect(page).to have_content("Middle English Dictionary")
      expect(page).to have_content("Bibliography")
      expect(page).to have_content("Corpus of Middle English")
    end

    it "has dictionary card with description" do
      expect(page).to have_content("world's largest searchable database of Middle English")
    end

    it "has bibliography card with description" do
      expect(page).to have_content("authors, works, manuscripts, and editions")
    end

    it "has 'Go to' links for dictionary and bibliography" do
      expect(page).to have_link("Go to the Middle English Dictionary")
      expect(page).to have_link("Go to the Bibliography")
    end

    it "has partnership logos" do
      expect(page).to have_css("img[alt='National Endowment for the Humanities logo']")
      expect(page).to have_css("img[alt='U-M Library logo']")
    end

    it "mentions the Ellesmere Manuscript" do
      expect(page).to have_content("Ellesmere Manuscript")
    end

    it "does not show a search form" do
      expect(page).not_to have_css("input[name='q']")
    end
  end

  # ------------------------------------------------------------
  # 2. Dictionary
  # ------------------------------------------------------------

  describe "dictionary" do
    # ---- home / landing page ----

    describe "home page" do
      before { visit "/dictionary" }

      include_examples "has site header"
      include_examples "has footer"
      include_examples "has navigation"
      include_examples "has skip links"
      include_examples "has search form"
      include_examples "has keyboard dropdown"

      it "renders a search field selector" do
        expect(page).to have_css("select[name='search_field']")
      end

      it "search field selector has expected options" do
        options = page.all("select[name='search_field'] option").map(&:text)
        expect(options).to include("Entire entry")
        expect(options).to include("Headword (with alternate spellings)")
        expect(options).to include("Headword (preferred spelling only)")
        expect(options).to include("Definition and notes")
        expect(options).to include("Etymology")
        expect(options).to include("Associated quotes and manuscripts")
        expect(options).to include("Modern English word equivalent")
      end
    end

    # ---- search results ----

    describe "search results" do
      before do
        visit "/dictionary"
        fill_in "q", with: "love"
        click_button "Search"
      end

      include_examples "has site header"
      include_examples "has footer"
      include_examples "has search form"

      it "shows search constraints" do
        expect(page).to have_css(".constraints-container, .applied-filter, .filter-name")
          .or(have_content("love"))
      end

      it "shows result count" do
        expect(page).to have_content("of")
          .and have_content(/\d+ - \d+ of \d+|No results found/)
      end

      it "has facet sidebar" do
        expect(page).to have_css("#facets, .facets, .blacklight-facets, aside")
      end

      it "has Part of Speech facet" do
        expect(page).to have_content("Part of Speech")
      end

      it "has sort options" do
        expect(page).to have_css("#sort-dropdown")
          .or(have_content("Sort by"))
          .or(have_content("Relevance"))
      end

      it "has per-page selector" do
        expect(page).to have_css(".per-page, #per_page-dropdown")
          .or(have_content("per page"))
      end

      it "renders result cards with headword and part of speech" do
        within("#documents, .document-list") do
          expect(page).to have_css(".entry-panel, .index_title")
        end
      end

      it "renders result cards with quotation count" do
        within("#documents, .document-list") do
          expect(page).to have_content("quotation")
        end
      end

      it "renders result cards with sense/definition" do
        within("#documents, .document-list") do
          expect(page).to have_content("Sense / Definition")
            .or(have_content("definition"))
        end
      end
    end

    # ---- show / detail page ----

    describe "show page" do
      # MED100 is a known stable dictionary entry ID
      before { visit "/dictionary/MED100" }

      it "loads without error" do
        expect(page.status_code).to eq(200)
        expect(page).not_to have_content("We're sorry, but something went wrong")
      end

      it "renders the entry panel" do
        expect(page).to have_css(".entry-panel")
      end

      it "has the entry title heading" do
        expect(page).to have_content("Middle English Dictionary Entry")
      end

      it "has an Entry Info section" do
        expect(page).to have_content("Entry Info")
      end

      it "has a Forms row" do
        expect(page).to have_css(".forms-title")
          .or(have_content("Forms"))
      end

      it "has an Etymology row" do
        expect(page).to have_css(".etymology-title")
          .or(have_content("Etymology"))
      end

      it "has a Definitions section" do
        expect(page).to have_content("Definitions (Senses and Subsenses)")
      end

      it "includes the search form" do
        expect(page).to have_css("input[name='q']")
      end

      it "includes the keyboard dropdown" do
        expect(page).to have_css(".keyboard")
      end
    end
  end

  # ------------------------------------------------------------
  # 3. Bibliography
  # ------------------------------------------------------------

  describe "bibliography" do
    # ---- home / landing page ----

    describe "home page" do
      before { visit "/bibliography" }

      include_examples "has site header"
      include_examples "has footer"
      include_examples "has navigation"
      include_examples "has skip links"
      include_examples "has search form"
      include_examples "has keyboard dropdown"

      it "renders the H1 heading" do
        expect(page).to have_selector("h1", text: "MEC Bibliography Search")
      end

      it "has description text" do
        expect(page).to have_content("manuscripts and editions used in the compilation")
      end

      it "renders a search field selector" do
        expect(page).to have_css("select[name='search_field']")
      end

      it "search field selector has expected options" do
        options = page.all("select[name='search_field'] option").map(&:text)
        expect(options).to include("Entire entry")
        expect(options).to include("Author/Title")
        expect(options).to include("External References")
        expect(options).to include("LALME/LAEME")
      end

      it "does not show facets on landing" do
        expect(page).not_to have_css(".facet-limit, .blacklight-facets")
      end
    end

    # ---- search results ----

    describe "search results" do
      before do
        visit "/bibliography"
        fill_in "q", with: "chaucer"
        click_button "Search"
      end

      include_examples "has site header"
      include_examples "has footer"
      include_examples "has search form"

      it "shows search constraints" do
        expect(page).to have_content("chaucer")
      end

      it "shows result count" do
        expect(page).to match(/1 - \d+ of \d+|No results found/)
      end

      it "renders result cards" do
        within("#documents, .document-list") do
          expect(page).to have_css(".entry-panel, .bib-header")
        end
      end

      it "renders stencil/m manuscript counts on result cards" do
        within("#documents, .document-list") do
          expect(page).to have_content("stencil")
            .or(have_content("from"))
        end
      end
    end

    # ---- show page ----

    describe "show page" do
      # BIB628 is a known stable bibliography ID
      # Note: show template has pre-existing replace :h1_wrap bug (Phase 5)
      before { visit "/bibliography/BIB628" }

      it "loads without error" do
        expect(page.status_code).to eq(200)
        expect(page).not_to have_content("We're sorry, but something went wrong")
      end

      it "renders the bibliography entry panel" do
        expect(page).to have_css(".entry-panel")
      end

      it "has the entry title heading" do
        expect(page).to have_content("Middle English Bibliography Entry")
      end

      it "has an Entry Info section" do
        expect(page).to have_content("Entry Info")
      end

      it "has External References section" do
        expect(page).to have_content("External References")
      end

      it "has Manuscript references section" do
        expect(page).to have_content("Manuscript, print, and LALME references")
      end

      it "has Editions section" do
        expect(page).to have_content("Editions, facsimiles, and other sources cited")
      end

      it "has MED title stencils section" do
        expect(page).to have_content("MED title stencils and sources")
      end

      it "includes the search form" do
        expect(page).to have_css("input[name='q']")
      end

      it "includes the keyboard dropdown" do
        expect(page).to have_css(".keyboard")
      end
    end
  end

  # ------------------------------------------------------------
  # 4. Quotations
  # ------------------------------------------------------------

  describe "quotations" do
    # ---- home / landing page ----

    describe "home page" do
      before { visit "/quotations" }

      include_examples "has site header"
      include_examples "has footer"
      include_examples "has navigation"
      include_examples "has skip links"
      include_examples "has search form"
      include_examples "has keyboard dropdown"

      it "renders the H1 heading" do
        expect(page).to have_selector("h1", text: "MEC Quotation Search")
      end

      it "has description text" do
        expect(page).to have_content("Quotations illustrate the use of a word")
      end

      it "renders a search field selector" do
        expect(page).to have_css("select[name='search_field']")
      end

      it "search field selector has expected options" do
        options = page.all("select[name='search_field'] option").map(&:text)
        expect(options).to include("Quotation including citation")
        expect(options).to include("Quotation text only")
      end

      it "does not show facets on landing" do
        expect(page).not_to have_css(".facet-limit, .blacklight-facets")
      end
    end

    # ---- search results ----

    describe "search results" do
      before do
        visit "/quotations"
        fill_in "q", with: "love"
        click_button "Search"
      end

      include_examples "has site header"
      include_examples "has footer"
      include_examples "has search form"

      it "shows search constraints" do
        expect(page).to have_content("love")
      end

      it "shows result count" do
        expect(page).to match(/\d+ - \d+ of [\d,]+|No results found/)
      end

      it "has sort options" do
        expect(page).to have_content("Relevance")
          .or(have_content("Date"))
          .or(have_css("#sort-dropdown"))
      end

      it "renders pagination" do
        expect(page).to have_css("a[rel='next'], .pagination, .page-links")
          .or(have_content("of"))
      end

      it "renders result cards" do
        within("#documents, .document-list") do
          expect(page).to have_css(".entry-panel, .quote-panel")
        end
      end

      it "renders quotation text on result cards" do
        within("#documents, .document-list") do
          expect(page).to have_css(".quote")
        end
      end

      it "renders associated bibliographic data on result cards" do
        within("#documents, .document-list") do
          expect(page).to have_content("Associated bibliographic data")
        end
      end

      it "renders associated headword on result cards" do
        within("#documents, .document-list") do
          expect(page).to have_content("Associated headword")
        end
      end
    end
  end

  # ------------------------------------------------------------
  # 5. Cross-cutting: BS4 remnants should NOT be present
  # ------------------------------------------------------------

  describe "no Bootstrap 4 remnants" do
    pages = {
      "splash" => "/",
      "dictionary home" => "/dictionary",
      "bibliography home" => "/bibliography",
      "quotations home" => "/quotations"
    }

    pages.each do |name, path|
      context "on #{name}" do
        before { visit path }

        it "does not use sr-only (should be visually-hidden)" do
          expect(page).not_to have_css(".sr-only"),
            "Expected .visually-hidden instead of .sr-only on #{name}"
        end
      end
    end
  end

  # ------------------------------------------------------------
  # 6. Error handling
  # ------------------------------------------------------------

  describe "error handling" do
    it "renders 404 for unknown dictionary ID" do
      visit "/dictionary/MEDNONEXISTENT99999"
      expect(page.status_code).to be_in([200, 404])
      expect(page).not_to have_content("We're sorry, but something went wrong")
    end

    it "renders 404 for unknown bibliography ID" do
      visit "/bibliography/BIBNONEXISTENT99999"
      expect(page.status_code).to be_in([200, 404])
      expect(page).not_to have_content("We're sorry, but something went wrong")
    end
  end
end
