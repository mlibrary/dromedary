require "representable/json"

module MiddleEnglishDictionary
  class Entry
    # A quoted passage from a historical source, corresponding to the +Q+
    # XML element within a +CIT+ (citation) node.
    #
    # All attributes are strings or arrays of strings extracted from the
    # inline markup of the +Q+ element. Most are optional and may be empty.
    #
    # @!attribute [rw] text
    #   @return [String] full text content of the +Q+ node, all inline markup
    #     stripped
    # @!attribute [rw] titles
    #   @return [Array<String>] unique text strings from +TITLE+ child nodes
    # @!attribute [rw] highlighted_phrases
    #   @return [Array<String>] unique text strings from +HI+ (highlighted)
    #     child nodes
    # @!attribute [rw] notes
    #   @return [Array<String>] note text strings from +NOTE+ child nodes,
    #     whitespace-normalized
    # @!attribute [rw] xml
    #   @return [String] raw XML of the +Q+ node
    # @!attribute [rw] entry_id
    #   @return [String, nil] ID of the owning {Entry}
    # @!attribute [rw] added
    #   @return [Object, nil] reserved for future use
    # @!attribute [rw] ovars
    #   @return [Object, nil] reserved for future use
    class Quote
      attr_accessor :titles, :added, :ovars, :highlighted_phrases,
        :text, :xml, :entry_id, :notes

      # Build a new {Quote} from a Nokogiri +Q+ element.
      #
      # @param nokonode [Nokogiri::XML::Element] the +Q+ node
      # @param entry_id [String, nil] ID of the owning entry
      # @return [Quote] new instance populated from the node
      def self.new_from_nokonode(nokonode, entry_id: nil)
        q = new
        q.entry_id = entry_id

        q.titles = nokonode.xpath("TITLE").map(&:text).uniq
        q.highlighted_phrases = nokonode.xpath("HI").map(&:text).uniq
        q.text = nokonode.text
        q.xml = nokonode.to_xml
        q.notes = nokonode.xpath("NOTE").map(&:text).map { |x| x.gsub(/[\s\n]+/, " ") }.map(&:strip)
        q
      end
    end

    # Representable decorator for {Quote}. Handles JSON round-tripping.
    # @api private
    class QuoteRepresenter < Representable::Decorator
      include Representable::JSON

      property :entry_id
      property :titles
      property :highlighted_phrases
      property :text
      property :xml
      property :notes
    end
  end
end
