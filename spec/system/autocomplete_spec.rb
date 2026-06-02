# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Autocomplete', type: :system do
  describe 'autocomplete configuration' do
    it 'has autocomplete enabled in blacklight config' do
      expect(CatalogController.blacklight_config.autocomplete_enabled).to be true
    end

    it 'does not reference Typeahead.js or Bloodhound in JS files' do
      js_files = Dir.glob(Rails.root.join('app/assets/javascripts/**/*.js')) +
                 Dir.glob(Rails.root.join('app/assets/javascripts/**/*.js.erb'))
      offenders = js_files.select { |f| File.read(f).match?(/typeahead|bloodhound/i) }
      expect(offenders).to be_empty, "Typeahead/Bloodhound references found in: #{offenders.join(', ')}"
    end
  end

  describe 'suggest endpoint returns HTML li fragments' do
    it 'headword suggester returns HTML li elements for prefix "ab"' do
      visit '/dictionary/suggest?q=ab&search_field=h'
      expect(page.status_code).to eq(200)
      expect(page.body).to include('<li')
      expect(page.body).to include('data-autocomplete-value')
    end

    it 'headword_forms suggester returns HTML li elements for prefix "ab"' do
      visit '/dictionary/suggest?q=ab&search_field=hnf'
      expect(page.status_code).to eq(200)
      expect(page.body).to include('<li')
    end

    it 'returns empty string for unconfigured search field' do
      visit '/dictionary/suggest?q=ab&search_field=everything'
      expect(page.status_code).to eq(200)
      expect(page.body.strip).to be_empty
    end
  end

  describe 'auto-complete element rendered on search pages' do
    it 'renders auto-complete element on dictionary home' do
      visit '/dictionary'
      expect(page).to have_css('auto-complete', wait: 5)
    end

    it 'renders auto-complete element on bibliography home' do
      visit '/bibliography'
      expect(page).to have_css('auto-complete', wait: 5)
    end

    it 'renders auto-complete element on quotations home' do
      visit '/quotations'
      expect(page).to have_css('auto-complete', wait: 5)
    end

    it 'renders auto-complete element in header search bar on results page' do
      visit '/dictionary?q=test&search_field=everything'
      expect(page).to have_css('auto-complete', wait: 5)
    end
  end
end
