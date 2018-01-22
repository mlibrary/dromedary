# frozen_string_literal: true

require 'json'
require 'delegate'
require 'dromedary/entry'

module Dromedary

  KeyDefPair = Struct.new(:letter, :definition)

  #convenience methods for a Sense
  module SplitDefinitionPresenter

    def has_initial_def?
      subdefs["initial"]
    end

    def has_lettered_defs?
      (subdefs.keys - ["initial"]).count > 0
    end

    def initial_def
      subdefs["initial"]
    end

    def sub_definitions
      subdefs.keys.reject {|x| x == "initial"}.map {|k| KeyDefPair.new(k, subdefs[k])}.sort {|a, b| a.letter <=> b.letter}
    end
  end

  class IndexPresenter < SimpleDelegator

    attr_reader :entry

    def initialize(document, view_context, configuration = view_context.blacklight_config)
      blacklight_index_presenter = Blacklight::IndexPresenter.new(document, view_context, configuration)
      __setobj__(blacklight_index_presenter)
      # we know we get @document for sure. Hydrate an Entry from the json
      @entry    = Dromedary::Entry.from_json(document.fetch('json'))
      @document = document

      # We can dig in and find out what type of search was done
      @search_field = view_context.search_state.params_for_search['search_field']
    end

    def senses
      @entry.senses.map {|x| x.extend(SplitDefinitionPresenter)}
    end


    def highlighted_official_headword
      Array(hl_field('official_headword')).first
    end

    def highlighted_other_spellings
       hl_field('headword').reject{|w| w == highlighted_official_headword}
    end

    def hl_field(k)
      if @document.has_highlight_field?(k)
        @document.highlight_field(k)
      elsif @document.has_field?(k)
        @document.fetch(k)
      else
        []
      end
    end

  end
end
