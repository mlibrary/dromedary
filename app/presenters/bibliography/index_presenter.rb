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
      include Dromedary::XSLTUtils::Class
      include Dromedary::XSLTUtils::Instance

      # @return [MiddleEnglishDictionary::Entry] The underlying entry object
      attr_reader :document, :bib, :nokonode

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


      def variants?
        not @nokonode.css('VARGROUP').empty?
      end

      def incipit?
        @bib.incipit? or @nokonode.at('TITLE').attr('TYPE') == 'INCIPIT'
      end


      COMMON_XSL  = load_xslt('bib/Common.xsl')
      MSGROUP_XSL = load_xslt('bib/MSGroup.xsl')

      def common_xsl
        load_xslt('bib/Common.xsl')
      end

      def msgroup_xsl
        load_xslt('bib/MSGroup.xsl')
      end

      def vargroup_xsl
        load_xslt('bib/Variant.xsl')
      end


      def commonify(xml_or_node)
        if xml_or_node.kind_of? String
          xsl_transform_from_xml(xml_or_node, COMMON_XSL)
        else
          xsl_transform_from_node(xml_or_node, COMMON_XSL)
        end

      end


      def title_html
        # require 'pry'; binding.pry
        title_node = @nokonode.at('TITLE')
        title = xsl_transform_from_node(title_node, COMMON_XSL)
        if bib.incipit?
          %Q(<div class="incipit">"#{title}&hellip;" (incipit)</div>)
        else
          title
        end
      end


      def ms_title_html(ms)
        xsl_transform_from_xml('<div>' + ms.title_xml + '</div>', COMMON_XSL)
      end

      def ms_lalme_html(ms)
        ms.lalme_xml.map{|x| xsl_transform_from_xml(x, COMMON_XSL)}.join(" ")
      end

      def ms_laeme_html(ms)
        ms.laeme_xml.map{|x| xsl_transform_from_xml(x, COMMON_XSL)}.join(" ")
      end



      def e_editions_xmls
        ee = @nokonode.xpath('//E-EDITION').map do |e|
          title = commonify(e.at('ED'))
          link  = e.at('LINK').text
          %Q(<a href="#{link}">#{title}</a>)
        end
      end


      # index = IMEV = Index of Middle English Verse
      # indexb = NIMEV = New Index of Middle English Verse
      # indexc = DIMEV = Digital Index of Middle English Verse
      # ipmep = IPMEP = Index of Printed Middle English Prose
      # severs = Manual = Manual of Writings in Middle English (ed. Severs, et al)
      # wells = Wells = Manual of Writings in Middle English (ed. Wells, et al)
      # Jolliffe = Jolliffe = A Check-list of Middle English Prose Writings of Spiritual Guidance

      def external_reference_kvpairs
        pairs = []
        pairs.push(['IMEV', bib.indexes.join(', ')]) unless bib.indexes.empty?
        pairs.push(['NIMEV', bib.indexbs.join(', ')]) unless bib.indexbs.empty?
        pairs.push(['DIMEV', bib.indexcs.join(', ')]) unless bib.indexcs.empty?
        pairs.push(['IPMEP', bib.ipmeps.join(', ')]) unless bib.ipmeps.empty?
        pairs.push(['Manual', bib.severs.join(', ')]) unless bib.severs.empty?
        pairs.push(['Wells', bib.wells.join(', ')]) unless bib.wells.empty?
        pairs.push(['Jolliffe', bib.jolliffes.join(', ')]) unless bib.jolliffes.empty?
        pairs
      end


      def editions_xmls
        editions = @nokonode.xpath('//STG/EDITION').map do |enode|
          commonify(enode)
        end
        (editions + e_editions_xmls).uniq
      end


      def msgroups_xmls
        @nokonode.xpath('//MSGROUP').map {|msg| xsl_transform_from_node(msg, msgroup_xsl)}
      end


      def num_stencils
        n = document.fetch('stencil_keyword').size
        "#{n} stencil".pluralize(n)
      end


      def num_manuscripts
        n = bib.manuscripts.size
        "#{n} manuscript".pluralize(n)
      end


      # Get the work of the first stencil, if available
      def first_work
        wrk = nokonode.at('.//STENCIL/WORK')
        if wrk
          xsl_transform_from_node(wrk, COMMON_XSL)
        else
          nil
        end
      end


    end

  end
end

