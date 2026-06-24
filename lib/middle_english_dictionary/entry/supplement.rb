require_relative "eg"
require "representable/json"

module MiddleEnglishDictionary
  class Entry
    # A supplementary section appended after the main sense content of an entry,
    # corresponding to the +SUPPLEMENT+ XML element.
    #
    # Supplements contain additional example groups ({EG}) and notes that did not
    # fit into the original sense structure of the dictionary entry.
    #
    # @!attribute [rw] egs
    #   @return [Array<EG>] example groups contained in this supplement
    # @!attribute [rw] notes
    #   @return [Array<String>] note text strings from +NOTE+ child nodes,
    #     whitespace-normalized
    # @!attribute [rw] entry_id
    #   @return [String, nil] ID of the owning {Entry}
    # @!attribute [rw] xml
    #   @return [String] raw XML of the +SUPPLEMENT+ node
    class Supplement
      attr_accessor :egs, :notes, :entry_id, :xml

      # Build a new {Supplement} from a Nokogiri +SUPPLEMENT+ element.
      #
      # @param nokonode [Nokogiri::XML::Element] the +SUPPLEMENT+ node
      # @param entry_id [String, nil] ID of the owning entry
      # @return [Supplement] new instance populated from the node
      def self.new_from_nokonode(nokonode, entry_id: nil)
        supp = new
        supp.entry_id = entry_id
        supp.egs = nokonode.css("EG").map { |eg| EG.new_from_nokonode(eg, entry_id: entry_id) }
        supp.notes = nokonode.xpath("NOTE").map(&:text).map { |x| x.gsub(/[\s\n]+/, " ") }.map(&:strip)
        supp.xml = nokonode.to_xml
        supp
      end
    end

    # Representable decorator for {Supplement}. Handles JSON round-tripping.
    #
    # Stores +objclass+ so that the mixed-type {Entry#sensestuff} array can be
    # re-hydrated to the correct class on deserialization.
    # @api private
    class SupplementRepresenter < Representable::Decorator
      include Representable::JSON

      property :objclass, getter: ->(represented:, **) { represented.class.to_s }, skip_parse: true

      property :entry_id
      property :xml
      property :notes

      collection :egs, decorator: EGRepresenter, class: EG
    end
  end
end
