# frozen_string_literal: true

require 'json'
require 'delegate'
require 'middle_english_dictionary'
require 'html_truncator'
require 'dromedary/xslt_utils'

module Dromedary

  module Quotes
    class IndexPresenter < SimpleDelegator

      extend Dromedary::XSLTUtils::Class
      include Dromedary::XSLTUtils::Class
      include Dromedary::XSLTUtils::Instance

      attr_reader :document, :citation, :nokonode

      # Create a new object in the same style as a Blacklight::IndexPresenter
      # This is not a subclass, but it delegates unknown methods to a
      # Blacklight::IndexPresenter underneath
      #
      # The main thing we do is provide the underlying MiddleEnglishDictionary::Entry
      # object.
      def initialize(document, view_context, configuration = view_context.blacklight_config)
        blacklight_index_presenter = Blacklight::IndexPresenter.new(document, view_context, configuration)
        __setobj__(blacklight_index_presenter)

        # we know we get @document for sure. Hydrate an Entry from the json
        @citation = MiddleEnglishDictionary::Entry::Citation.from_json(document.fetch('json'))
        @document = document

        # Get the nokonode for later XSL processing
        @nokonode = Nokogiri::XML(@citation.xml)

        # We can dig in and find out what type of search was done
        @search_field = view_context.search_state.params_for_search['search_field']
      end

      # TODO No reason to load these from disk each time in production
      def common_xsl
        load_xslt('Common.xsl')
      end

      def citation_xsl
        # load_xslt('quotes/QuoteCitation.xsl')
        load_xslt('CitOnly.xsl')
      end

      def citation_link_text
        xsl_transform_from_xml(@citation.bib.stencil.xml, citation_xsl)
      end

    end

  end
end

