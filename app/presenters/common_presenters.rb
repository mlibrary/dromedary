module Dromedary
  module CommonPresenters


    # Find the first field in a solr document that you have a value for
    def first_found_value_as_highlighted_array(document, list_of_fieldnames, default=[])
      list_of_fieldnames.map{|f| hl_field(document, f)}.reject{|x| x.empty?}.first || []
    end


    # A convenience method to get the highlighted values for a field if
    # they're available, falling back to the regular document values for
    # that field if they're not in the highlighted values section of the
    # Solr response
    #
    # @param [String] Name of the solr field
    # @return [Array<String>] The highlighted versions of the field given,
    # or the non-highlighted values if there aren't any highlights.
    def hl_field(document, k)
      if document.has_highlight_field?(k) and !document.highlight_field(k).empty?
        Array(document.highlight_field(k))
      elsif document.has_field?(k)
        Array(document.fetch(k))
      else
        []
      end
    end

    def headword_display(document)
      hw = first_found_value_as_highlighted_array(document, ['official_headword', 'headword']).join(', ')
      if document.has_key?('dubious')
        "?#{hw}"
      else
        hw
      end
    end

  end
end
