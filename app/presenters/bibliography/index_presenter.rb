# frozen_string_literal: true

require 'json'
require 'delegate'
require 'middle_english_dictionary'
require 'html_truncator'
require 'dromedary/xslt_utils'

module Dromedary

  module Bib
    class IndexPresenter < SimpleDelegator

      extend Dromedary::XSLTUtils::Class
      include Dromedary::XSLTUtils::Instance

      # @return [MiddleEnglishDictionary::Entry] The underlying entry object
      attr_reader :document

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
        @bib      = MiddleEnglishDictionary::Bib.from_json(document.fetch('json'))
        @document = document

        # Get the nokonode for later XSL processing
        @nokonode = Nokogiri::XML(@bib.xml)

        # We can dig in and find out what type of search was done
        @search_field = view_context.search_state.params_for_search['search_field']
      end


      TITLE_XSL = load_xslt('bib/Common.xsl')

      def title_html
        # require 'pry'; binding.pry
        title_node = @nokonode.at('TITLE')
        html = xsl_transform_from_node(title_node, TITLE_XSL)
        if @bib.incipit? or title_node.attr('TYPE') == 'INCIPIT'
          html = "\"#{html}&hellip;\" (incipit)"
        end
        html
      end

      def num_stencils
        n = @document.fetch('stencil_keyword').size
        "#{n} stencil".pluralize(n)
      end

      def num_manuscripts
        n = @bib.manuscripts.size
        "#{n} manuscript".pluralize(n)
      end





    end

  end
end

