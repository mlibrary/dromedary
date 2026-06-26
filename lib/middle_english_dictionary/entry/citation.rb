require_relative "bib"
require_relative "quote"
require "representable/json"
module MiddleEnglishDictionary
  class Entry
    # An individual citation from a historical source, corresponding to the
    # +CIT+ XML element within an {EG} (example group) node.
    #
    # Every citation pairs a quoted passage ({Quote}) with structured
    # bibliographic information ({Bib}). It may also carry integer estimates
    # of the work's composition date (+cd+) and the manuscript's date (+md+).
    #
    # @!attribute [rw] quote
    #   @return [Quote] the quoted passage extracted from the +Q+ child node
    # @!attribute [rw] bib
    #   @return [Bib] bibliographic reference extracted from the +BIBL+ child
    #     node
    # @!attribute [rw] cd
    #   @return [Integer, nil] estimated composition date of the cited work,
    #     from the +CD+ attribute (nil if absent)
    # @!attribute [rw] md
    #   @return [Integer, nil] estimated date of the specific manuscript, from
    #     the +MD+ attribute (nil if absent)
    # @!attribute [rw] text
    #   @return [String] full text content of the +CIT+ node, all markup stripped
    # @!attribute [rw] notes
    #   @return [Array<String>] note text strings from +NOTE+ child nodes,
    #     whitespace-normalized
    # @!attribute [rw] entry_id
    #   @return [String, nil] ID of the owning {Entry}
    # @!attribute [rw] xml
    #   @return [String] raw XML of the +CIT+ node
    class Citation
      attr_accessor :quote, :cd, :md, :bib, :xml, :entry_id, :notes, :text

      # Build a new {Citation} from a Nokogiri +CIT+ element.
      #
      # @param nokonode [Nokogiri::XML::Element] the +CIT+ node
      # @param entry_id [String, nil] ID of the owning entry
      # @return [Citation] new instance populated from the node
      def self.new_from_nokonode(nokonode, entry_id: nil)
        cite = new
        cite.entry_id = entry_id
        cite.md = nokonode.attr("MD") && nokonode.attr("MD").to_i
        cite.cd = nokonode.attr("CD") && nokonode.attr("CD").to_i
        cite.quote = Quote.new_from_nokonode(nokonode.at("Q"), entry_id: entry_id)
        cite.bib = Bib.new_from_nokonode(nokonode.at("BIBL"), entry_id: entry_id)
        cite.notes = nokonode.xpath("NOTE").map(&:text).map { |x| x.gsub(/[\s\n]+/, " ") }.map(&:strip)
        cite.text = nokonode.text
        cite.xml = nokonode.to_xml
        cite
      end

      # Serialize this citation and all its sub-objects to JSON.
      #
      # @return [String] JSON representation
      def to_json
        CitationRepresenter.new(self).to_json
      end

      # Deserialize a {Citation} from JSON produced by {#to_json}.
      #
      # @param j [String] JSON string
      # @return [Citation] re-hydrated citation
      def self.from_json(j)
        CitationRepresenter.new(new).from_json(j)
      end
    end

    # Representable decorator for {Citation}. Handles JSON round-tripping.
    # @api private
    class CitationRepresenter < Representable::Decorator
      include Representable::JSON

      property :entry_id
      property :md
      property :cd
      property :quote, decorator: QuoteRepresenter, class: Quote
      property :bib, decorator: BibRepresenter, class: Bib
      property :notes
      property :text
      property :xml
    end
  end
end
