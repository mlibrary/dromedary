require "representable/json"

module MiddleEnglishDictionary
  class Entry
    # A bibliographic stencil -- the core citation reference within a MED entry.
    #
    # A stencil corresponds to the +STNCL+ XML element inside a +BIBL+ node.
    # It captures structured bibliographic metadata for a historical source
    # cited in a sense example, and provides the +rid+ attribute used to
    # cross-reference the full record in the hyperbib ({Bib}).
    #
    # @!attribute [rw] rid
    #   @return [String, nil] cross-reference ID (+RID+ attribute) linking this
    #     stencil to a {Bib} entry in the hyperbib
    # @!attribute [rw] date
    #   @return [String, nil] raw text content of the +DATE+ child node
    # @!attribute [rw] author
    #   @return [String, nil] text of the +AUTHOR+ child node
    # @!attribute [rw] title
    #   @return [Array<String>] text of all +TITLE+ child nodes
    # @!attribute [rw] ms
    #   @return [String, nil] text of the first +MS+ child node (manuscript
    #     siglum)
    # @!attribute [rw] highlighted_phrases
    #   @return [Array<String>] unique text strings from +HI+ child nodes
    # @!attribute [rw] notes
    #   @return [Array<String>] note text strings, whitespace-normalized
    # @!attribute [rw] entry_id
    #   @return [String, nil] ID of the owning {Entry}
    # @!attribute [rw] xml
    #   @return [String] raw XML of the +STNCL+ node
    class Stencil
      attr_accessor :rid, :date, :highlighted_phrases,
        :author, :title, :ms, :entry_id, :notes, :xml

      # Build a new {Stencil} from a Nokogiri +STNCL+ element.
      #
      # @param nokonode [Nokogiri::XML::Element] the +STNCL+ node
      # @param entry_id [String, nil] ID of the owning entry
      # @return [Stencil] new instance populated from the node
      def self.new_from_nokonode(nokonode, entry_id: nil)
        stencil = new
        stencil.entry_id = entry_id
        stencil.xml = nokonode.to_xml

        stencil.author = nokonode.xpath("AUTHOR").map(&:text).first
        stencil.rid = nokonode.attr("RID")
        stencil.date = nokonode.xpath("DATE").map(&:text).first
        stencil.highlighted_phrases = nokonode.css("HI").map(&:text).uniq
        stencil.title = nokonode.xpath("TITLE").map(&:text)
        stencil.ms = nokonode.xpath("MS").map(&:text).first
        stencil.notes = nokonode.xpath("NOTE").map(&:text).map { |x| x.gsub(/[\s\n]+/, " ") }.map(&:strip)
        stencil
      end
    end

    # Representable decorator for {Stencil}. Handles JSON round-tripping.
    # @api private
    class StencilRepresenter < Representable::Decorator
      include Representable::JSON

      property :entry_id
      property :xml

      property :rid
      property :date
      property :highlighted_phrases
      property :author
      property :title
      property :ms

      property :notes
    end
  end
end
