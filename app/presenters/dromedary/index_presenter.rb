# frozen_string_literal: true

require 'json'
require 'delegate'

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

  class IndexPresenter < Blacklight::IndexPresenter
    attr_reader :entry

    def initialize(document, view_context, configuration = view_context.blacklight_config)
      super
      # we know we get @document for sure. Hydrate an Entry from the json
      @entry = Dromedary::Entry.from_json(@document.fetch('json'))
    end

    def senses
      @entry.senses.map{|x| x.extend(SplitDefinitionPresenter)}
    end


  end
end
