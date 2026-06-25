# frozen_string_literal: true

# Blacklight 9's SearchBarComponent only pre-selects the search-field
# dropdown from `params[:search_field]`. On landing pages (dictionary /
# bibliography / quotations splash, and the header search bar) there is no
# such param, so the <select> falls back to its first <option> ("Entire
# entry") instead of the field marked `default: true` in the controller
# config.
#
# The original (Blacklight 7 / Bootstrap 3) app pre-selected the configured
# default (e.g. "Headword (with alternate spellings)"). Restore that behavior
# globally by defaulting @search_field to the configured default field at
# render time (helpers / blacklight_config are available in before_render but
# not in #initialize).
Rails.application.config.to_prepare do
  module DromedarySearchBarDefaultField
    def before_render
      super
      @search_field ||= default_search_field_key
    end

    private

    def default_search_field_key
      default_field = blacklight_config.search_fields.values.find { |field| field[:default] }
      default_field&.key
    end
  end

  Blacklight::SearchBarComponent.prepend(DromedarySearchBarDefaultField)
end
