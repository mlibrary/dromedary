# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Keyboard dropdown', type: :system do
  shared_examples 'keyboard dropdown' do
    it 'renders the keyboard dropdown button' do
      expect(page).to have_css('.keyboard')
    end

    it 'contains special character buttons' do
      expect(page).to have_content('Þ')
      expect(page).to have_content('Ð')
      expect(page).to have_content('Ʒ')
      expect(page).to have_content('Æ')
    end
  end

  context 'dictionary home' do
    before { visit '/dictionary' }
    include_examples 'keyboard dropdown'
  end

  context 'bibliography home' do
    before { visit '/bibliography' }
    include_examples 'keyboard dropdown'
  end

  context 'quotations home' do
    before { visit '/quotations' }
    include_examples 'keyboard dropdown'
  end

  context 'header search bar' do
    before { visit '/dictionary?q=test&search_field=hnf' }
    include_examples 'keyboard dropdown'
  end
end
