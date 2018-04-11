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

      # We can dig in and find out what type of search was done
      @search_field = view_context.search_state.params_for_search['search_field']
    end

    # @return [String] The cleaned-up POS abbreviation (e.g., "n" or "v")
    def part_of_speech_abbrev
      @document.fetch('pos_abbrev')
    end

    # @return [Array<MiddleEnglishDictionary::Sense>] All the entry senses
    # modified to replace '~' with regularized headword
    def senses
      binding.pry
      headw = @entry.headwords.first.instance_variable_get(:@regs).first
      # @entry.senses.each { |sen| sen.definition_xml.gsub! '~', headw}
      puts "HEADWORD: #{headw}"
      @entry.senses.each do |s|
        puts "BEFORE FIX SENSE XML: #{s.definition_xml}"
        s.definition_xml.gsub! '~', headw
        puts "AFTER FIX: #{s.definition_xml}"
      end
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
