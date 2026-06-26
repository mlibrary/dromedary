# frozen_string_literal: true

require "json"
require "delegate"
require "middle_english_dictionary"
require "html_truncator"
require "dromedary/xslt_utils"
require "dromedary/smart_xml"
require_relative "../common_presenters"
module Dromedary
  class IndexPresenter < SimpleDelegator
    include Rails.application.routes.url_helpers
    include CommonPresenters

    extend Dromedary::XSLTUtils::Class
    include Dromedary::XSLTUtils::Class
    include Dromedary::XSLTUtils::Instance

    # @return [MiddleEnglishDictionary::Entry] The underlying entry object
    attr_reader :entry

    # Create a presenter that wraps a Blacklight::IndexPresenter and exposes
    # the parsed MED entry plus XSLT helpers for index rendering.
    #
    # @param [Blacklight::SolrDocument] document Solr document for the entry
    # @param [ActionView::Base] view_context view context for helpers/config
    # @param [Blacklight::Configuration, nil] configuration optional Blacklight config
    def initialize(document, view_context, configuration = view_context.blacklight_config)
      blacklight_index_presenter = Blacklight::IndexPresenter.new(document, view_context, configuration)
      __setobj__(blacklight_index_presenter)
      # we know we get @document for sure. Hydrate an Entry from the json
      @entry = MiddleEnglishDictionary::Entry.from_json(document.fetch("json"))
      @document = document

      # Get the nokonode for later XSL processing
      @nokonode = Nokogiri::XML(@document.fetch("xml"))

      # We can dig in and find out what type of search was done
      @search_field = view_context.search_state.params_for_search["search_field"]
    end

    ##### XSLT TRANSFORMS #####

    # @return [String, nil] HTML for the entry FORM section, or nil if absent
    def form_html
      xsl_transform_from_entry("/ENTRYFREE/FORM", load_xslt("FormOnly.xsl"))
    end

    # @return [String, nil] HTML for the entry ETYM section, or nil if absent
    def etym_html
      xsl_transform_from_entry("/ENTRYFREE/ETYM", load_xslt("EtymOnly.xsl"))
    end

    # @return [Array<String>] ETYM language abbreviations for the entry
    def language_abbreviations
      entry.etym_languages
    end

    # @return [Hash<String, String>] ETYM abbreviations mapped to expanded names
    def language_mapping
      @nokonode.xpath("//ETYM/LANG/LG").each_with_object({}) do |n, h|
        h[n.text] = n["EXPAN"]
      end
    end

    # @param [MiddleEnglishDictionary::Entry::Sense,MiddleEnglishDictionary::Entry::SenseGrp] sense sense to render
    # @return [SmartXML, nil] HTML for the sense definition, or nil if absent
    def def_html(sense)
      enclosed_def_xml = "<div>" + sense.definition_xml + "</div>"

      Dromedary::SmartXML.new(xsl_transform_from_xml(enclosed_def_xml, load_xslt("DefOnly.xsl")))
    end

    # @param [MiddleEnglishDictionary::Entry::Note] note note to render
    # @return [String, nil] HTML for the note, or nil if absent
    def note_html(note)
      xsl_transform_from_xml(note.xml, load_xslt("NoteOnly.xsl"))
    end

    # @param [MiddleEnglishDictionary::Entry::Supplement] supplement supplement to render
    # @return [String, nil] HTML for the supplement, or nil if absent
    def supplement_html(supplement)
      xsl_transform_from_xml(supplement.xml, load_xslt("SupplementOnly.xsl"))
    end

    ####### Ealier Methods #####

    # @return [String] cleaned-up part-of-speech abbreviation
    def part_of_speech_abbrev
      @entry.pos
    end

    # @return [Array<MiddleEnglishDictionary::Sense>] entry senses with "~" replaced by the regularized headword
    def senses
      headw = @entry.headwords.first.instance_variable_get(:@regs).first
      @entry.senses.each { |sen| sen.definition_xml.gsub! "~", headw }
      @entry.senses
    end

    # @return [Array<MiddleEnglishDictionary::Sense, MiddleEnglishDictionary::Entry::SenseGrp, MiddleEnglishDictionary::Entry::Supplement, MiddleEnglishDictionary::Entry::Note>] all sense-related entry content
    def sensestuff
      @entry.sensestuff
    end

    # @return [Integer] total quote count across all senses
    def quote_count
      @entry.all_quotes.count
    end

    ### XSL  ###

    # @param [String] xpath XPath under +/ENTRYFREE+ to transform
    # @param [Nokogiri::XSLT] xslt stylesheet to apply
    # @return [String, nil] transformed HTML, or nil if the xpath is missing
    def xsl_transform_from_entry(xpath, xslt)
      xsl_transform_from_node(doc_from_xpath(xpath), xslt)
    end

    # @return [String, nil] primary highlighted headword from Solr
    def highlighted_official_headword
      Array(hl_field(document, "headword")).first
    end

    # @return [Array<String>] alternate highlighted spellings from Solr
    def highlighted_other_spellings
      hl_field(document, "headword").reject { |w| w == highlighted_official_headword }
    end

    # @param [Hash, Blacklight::SolrDocument] document Solr document to display from
    # @return [String] display headword, prefixed with ? when dubious
    def headword_display(document)
      hw = entry.original_headwords.join(", ")
      if document.has_key?("dubious")
        "?#{hw}"
      else
        hw
      end
    end
  end
end
