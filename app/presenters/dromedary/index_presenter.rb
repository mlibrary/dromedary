# frozen_string_literal: true

require 'json'
require 'delegate'
require 'middle_english_dictionary'

module Dromedary

  class IndexPresenter < SimpleDelegator

    # @return [MiddleEnglishDictionary::Entry] The underlying entry object
    attr_reader :entry

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
      @entry    = MiddleEnglishDictionary::Entry.from_json(document.fetch('json'))
      @document = document

      # Get the nokonode for later XSL processing
      @nokonode = Nokogiri::XML(@document.fetch('xml'))

      # We can dig in and find out what type of search was done
      @search_field = view_context.search_state.params_for_search['search_field']
    end

    ##### XSLT TRANSFORMS #####

    def form_xslt
      @form_xsl ||= Nokogiri::XSLT(File.read('./indexer/xslt/FormOnly.xsl'))
    end

    def def_xslt
      @def_xslt ||= Nokogiri::XSLT(File.read('./indexer/xslt/DefOnly.xsl'))
    end

    def cit_xslt
      @cit_xslt ||= Nokogiri::XSLT(File.read('./indexer/xslt/CitOnly.xsl'))
      puts "IN INDEXPRESENTER @cit_xslt IS: #{@cit_xslt}"
    end

    def etym_xslt
      @etym_xslt ||= Nokogiri::XSLT(File.read('./indexer/xslt/EtymOnly.xsl'))
    end

    def note_xslt
      @note_xslt ||= Nokogiri::XSLT(File.read('./indexer/xslt/NoteOnly.xsl'))
    end

    def supplement_xslt
      @supplement_xslt ||= Nokogiri::XSLT(File.read('./indexer/xslt/SupplementOnly.xsl'))
    end

    ####### Getting nokogiri nodes #####

    # def entry_node
    #   @nokonode = Nokogiri::XML(@entry_nokonode)
    # end

    # @return [Nokogiri::Node | nil] nil if there isn't a FORM section, the node otherwise
    def form_doc
      doc_from('/ENTRYFREE/FORM')
    end

    def doc_from(xpath)
      node = @nokonode.xpath(xpath)
      node = node.first
      return nil if node.nil?
      doc = Nokogiri::XML::Document.new
      doc.add_child node.dup
      doc
    end


    # There's only one FORM section, so just take care of it here
    # @return [String] the transformed form
    def form_html
      return nil unless form_doc
      form_xslt.apply_to(form_doc)
    end

    # There's only one ETYM section, so just take care of it here
    # @return [String] the transformed form
    def etym_doc
      doc_from('/ENTRYFREE/ETYM')
    end

    def etym_html
      return nil unless etym_doc
      etym_xslt.apply_to(etym_doc)
    end  

    # @param [MiddleEnglishDictionary::Entry::Sense] sense The sense whose def you want
    # @return [String] The definition transformed into HTML
    def def_html(sense)
      return nil unless sense.definition_xml
      nokonode = Nokogiri::XML(sense.definition_xml)
      def_xslt.apply_to(nokonode)
    end

    def note_html(note)
      return nil unless note.xml
      nokonode = Nokogiri::XML(note.xml)
      note_xslt.apply_to(nokonode)
    end

    def cit_html(cit)
      sten = cit.bib.stencil
      x = sten.instance_variable_get(:@xml)
      puts "IN CIT_HTML cit is #{cit}"
      puts "IN CIT_HTML sten is #{sten}"
      puts "IN CIT_HTML sten.xml is #{x}"
      return nil unless x
      # nokonode = Nokogiri::XML(x)
      cit_doc = doc_from(x)
      puts "IN CIT_HTML cit_doc is #{cit_doc}"
      cit_doc

      # html = cit_xslt.apply_to(nokonode)
      # puts "IN CIT_HTML html is #{html}"
      # html
    end

    def supplement_node(supplement)
      Nokogiri::XML(supplement.xml)
    end

    def supplement_html(supplement)
      return nil unless supplement.xml
      nokonode = Nokogiri::XML(supplement.xml)
      supplement_xslt.apply_to(nokonode)
    end

    ####### Ealier Methods #####

    # @return [String] The cleaned-up POS abbreviation (e.g., "n" or "v")
    def part_of_speech_abbrev
      @entry.pos
    end

    # @return [Array<MiddleEnglishDictionary::Sense>] All the entry senses
    # modified to replace '~' with regularized headword
    def senses
      headw = @entry.headwords.first.instance_variable_get(:@regs).first
      @entry.senses.each { |sen| sen.definition_xml.gsub! '~', headw}
      @entry.senses
    end

    # @return [Integer] The number of quotes across all senses
    def quote_count
      @entry.all_quotes.count
    end


    # @return [Array<String>] The headwords as taken from the "highlight"
    # section of the solr return (with embedded tags for highlighting)
    def highlighted_official_headword
      Array(hl_field('official_headword')).first
    end

    # @return [Array<String>] The non-headword spellings as taken from the "highlight"
    # section of the solr return (with embedded tags for highlighting)
    def highlighted_other_spellings
       hl_field('headword').reject{|w| w == highlighted_official_headword}
    end

    private

    # A convenience method to get the highlighted values for a field if
    # they're available, falling back to the regular document values for
    # that field if they're not in the highlighted values section of the
    # Solr response
    #
    # @param [String] Name of the solr field
    # @return [Array<String>] The highlighted versions of the field given,
    # or the non-highlighted values if there aren't any highlights.
    def hl_field(k)
      if @document.has_highlight_field?(k)
        @document.highlight_field(k)
      elsif @document.has_field?(k)
        Array(@document.fetch(k))
      else
        []
      end
    end

  end
end

