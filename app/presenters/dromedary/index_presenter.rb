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
      subdefs.keys.reject{|x| x == "initial"}.map{|k| KeyDefPair.new(k, subdefs[k])}.sort{|a,b| a.letter <=> b.letter}
    end
  end

  class IndexPresenter < SimpleDelegator

    attr_reader :entry

    def initialize(document, view_context, configuration = view_context.blacklight_config)
      blacklight_index_presenter = Blacklight::IndexPresenter.new(document, view_context, configuration)
      __setobj__(blacklight_index_presenter)
      # we know we get @document for sure. Hydrate an Entry from the json
      @entry = Dromedary::Entry.from_json(document.fetch('json'))
      @document = document
    end

    def senses
      @entry.senses.map{|x| x.extend(SplitDefinitionPresenter)}
    end


    def highlighted_main_headword
      Array(hl_field('main_headword')).first
    end

    def hl_field(k)
      if @document.has_highlight_field?(k)
        @document.highlight_field(k)
      else
        @document.fetch(k)
      end
    end

  end
end
