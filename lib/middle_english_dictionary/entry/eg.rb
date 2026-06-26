require "middle_english_dictionary/entry/class_methods"
require_relative "citation"
require "representable/json"

module MiddleEnglishDictionary
  class Entry
    # An example group (EG) -- a container for one or more citations ({Citation})
    # illustrating a sense or sub-definition, corresponding to the +EG+ XML
    # element.
    #
    # The optional +N+ attribute on the +EG+ node carries a sub-definition
    # letter (e.g. "a", "b") that further subdivides the examples within a
    # sense.
    #
    # @!attribute [rw] citations
    #   @return [Array<Citation>] individual citations contained in this group
    # @!attribute [rw] subdef_entry
    #   @return [String] lowercase sub-definition letter from the +N+ attribute,
    #     or an empty string if absent
    # @!attribute [rw] entry_id
    #   @return [String, nil] ID of the owning {Entry}
    # @!attribute [rw] notes
    #   @return [Array<String>] note text strings from +NOTE+ child nodes,
    #     whitespace-normalized
    # @!attribute [rw] xml
    #   @return [String] raw XML of the +EG+ node
    class EG
      attr_accessor :citations, :subdef_entry, :entry_id, :xml, :notes

      # Build a new {EG} from a Nokogiri +EG+ element.
      #
      # @param nokonode [Nokogiri::XML::Element] the +EG+ node
      # @param entry_id [String, nil] ID of the owning entry
      # @return [EG] new instance populated from the node
      def self.new_from_nokonode(nokonode, entry_id: nil)
        eg = new
        eg.xml = nokonode.to_xml
        eg.subdef_entry = (nokonode.attr("N") || "").downcase
        eg.citations = nokonode.xpath("CIT").map { |cit| Citation.new_from_nokonode(cit, entry_id: entry_id) }
        eg.entry_id = entry_id
        eg.notes = nokonode.xpath("NOTE").map(&:text).map { |x| x.gsub(/[\s\n]+/, " ") }.map(&:strip)

        eg
      end

      # All {Quote} objects from every citation in this group.
      #
      # @return [Array<Quote>] flat list of quotes
      def quotes
        citations.flat_map(&:quote)
      end
    end

    # Representable decorator for {EG}. Handles JSON round-tripping.
    # @api private
    class EGRepresenter < Representable::Decorator
      include Representable::JSON

      property :entry_id
      property :subdef_entry
      property :xml
      collection :citations, decorator: CitationRepresenter, class: Citation
      property :notes
    end
  end
end
