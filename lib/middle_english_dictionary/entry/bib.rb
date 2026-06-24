require_relative "stencil"
require "representable/json"

module MiddleEnglishDictionary
  class Entry
    # A citation-level bibliographic reference, corresponding to the +BIBL+
    # XML element within a +CIT+ (citation) node.
    #
    # A +Bib+ is a thin wrapper around a {Stencil} that also carries the
    # optional +SCOPE+ value (folio/page range or other locator) and any
    # inline notes.
    #
    # @!attribute [rw] stencil
    #   @return [Stencil, nil] the structured bibliographic stencil extracted
    #     from the +STNCL+ child node
    # @!attribute [rw] scope
    #   @return [String, nil] text of the first +SCOPE+ child node
    # @!attribute [rw] entry_id
    #   @return [String, nil] ID of the owning {Entry}
    # @!attribute [rw] notes
    #   @return [Array<String>] note text strings from +NOTE+ child nodes,
    #     whitespace-normalized
    class Bib
      attr_accessor :stencil, :scope, :entry_id, :notes

      # Build a new {Bib} from a Nokogiri +BIBL+ element.
      #
      # @param nokonode [Nokogiri::XML::Element] the +BIBL+ node
      # @param entry_id [String, nil] ID of the owning entry
      # @return [Bib] new instance populated from the node
      def self.new_from_nokonode(nokonode, entry_id: nil)
        stencil_node = nokonode.at("STNCL")
        bib = new
        bib.entry_id = entry_id
        bib.stencil = Stencil.new_from_nokonode(stencil_node, entry_id: entry_id)
        bib.scope = nokonode.xpath("SCOPE").map(&:text).first
        bib.notes = nokonode.xpath("NOTE").map(&:text).map { |x| x.gsub(/[\s\n]+/, " ") }.map(&:strip)
        bib
      end
    end

    # Representable decorator for {Bib}. Handles JSON round-tripping.
    # @api private
    class BibRepresenter < Representable::Decorator
      include Representable::JSON

      property :scope
      property :entry_id
      property :stencil, decorator: StencilRepresenter, class: Stencil
      property :notes
    end
  end
end
