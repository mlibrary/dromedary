# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BS5 compliance', type: :system do
  describe 'splash page' do
    before { visit '/' }

    it 'does not use sr-only' do
      expect(page).not_to have_css('.sr-only')
    end

    it 'does not use data-toggle' do
      expect(page).not_to have_selector('[data-toggle]')
    end
  end

  describe 'dictionary home' do
    before { visit '/dictionary' }

    it 'does not use sr-only' do
      expect(page).not_to have_css('.sr-only')
    end

    it 'does not use data-toggle' do
      expect(page).not_to have_selector('[data-toggle]')
    end

    it 'does not use data-target' do
      expect(page).not_to have_selector('[data-target]')
    end
  end

  describe 'bibliography home' do
    before { visit '/bibliography' }

    it 'does not use sr-only' do
      expect(page).not_to have_css('.sr-only')
    end
  end

  describe 'quotations home' do
    before { visit '/quotations' }

    it 'does not use sr-only' do
      expect(page).not_to have_css('.sr-only')
    end
  end

  describe 'dictionary search results' do
    before { visit '/dictionary?q=women&search_field=hnf' }

    it 'does not use sr-only' do
      expect(page).not_to have_css('.sr-only')
    end
  end
end
