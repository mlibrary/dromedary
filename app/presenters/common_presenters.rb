require 'annoying_utilities'


module CommonPresenters

  include Rails.application.routes.url_helpers

  include ActionView::Helpers::UrlHelper

  # Find the first field in a solr document that you have a value for
  def first_found_value_as_highlighted_array(document, list_of_fieldnames, default = [])
    list_of_fieldnames.map {|f| hl_field(document, f)}.reject {|x| x.empty?}.first || []
  end

  def cit_xslt
    load_xslt('CitOnly.xsl')
  end

  # @param [MiddleEnglishDictionary::Entry::Citation] cit The citation object
  # @return [String, nil] The citatation transformed into HTML, or nil
  def cit_html(cit)
    rid = cit.bib.stencil.rid
    if rid
      bibid = Dromedary.hyp_to_bibid[rid.upcase] if rid
      url   = bib_link_path(bibid)
      xsl_transform_from_xml(cit.xml, cit_xslt, ["biburl", "'#{url}'"])
    end

  end

  alias_method :cite_html, :cit_html
  alias_method :citation_html, :cit_html


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
