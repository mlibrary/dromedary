module MiddleEnglishDictionary
  class Bib
    # A manuscript reference within a hyperbib ({Bib}) entry, corresponding
    # to an +MS+ element inside the +MSLIST+ of a +HYPERMED/ENTRY+ node.
    #
    # Each +MS+ records the manuscript siglum, an optional preference indicator,
    # a folio/page citation, and optional dialect-atlas data from the Linguistic
    # Atlas of Late Mediaeval English (LALME) and the Linguistic Atlas of Early
    # Middle English (LAEME). The {#title} and {#title_xml} attributes are
    # populated by {Collection::BibSet} after construction by looking up
    # {#ref} in a {Collection::MSNames} index.
    #
    # @example
    #   # <MS REF="CORP-O"><CITE>155</CITE><LALME>vol. 1. 152. Lincs.</LALME></MS>
    #
    # @!attribute [rw] ref
    #   @return [String, nil] manuscript code from the +REF+ attribute
    #     (e.g. +"CORP-O"+)
    # @!attribute [rw] pref
    #   @return [:all, :part, nil] preference indicator derived from the +PREF+
    #     attribute: +:all+ when +"Y"+, +:part+ when +"PART"+, +nil+ otherwise
    # @!attribute [rw] cite
    #   @return [String, nil] folio/page citation from the +CITE+ child node,
    #     or +nil+ if absent or empty
    # @!attribute [rw] lalme
    #   @return [Array<String>, nil] text of all +LALME+ child nodes, or +nil+
    #     if no LALME data is present
    # @!attribute [rw] lalme_xml
    #   @return [Array<String>, nil] raw XML of all +LALME+ child nodes
    # @!attribute [rw] lalme_regions
    #   @return [Array<String>] expanded region names from
    #     +LALME/REGION/@EXPAN+
    # @!attribute [rw] laeme
    #   @return [Array<String>, nil] text of all +LAEME+ child nodes, or +nil+
    #     if no LAEME data is present
    # @!attribute [rw] laeme_xml
    #   @return [Array<String>, nil] raw XML of all +LAEME+ child nodes
    # @!attribute [rw] laeme_regions
    #   @return [Array<String>] expanded region names from
    #     +LAEME/REGION/@EXPAN+
    # @!attribute [rw] title
    #   @return [String, nil] plain-text manuscript title, resolved from
    #     {Collection::MSNames} after construction
    # @!attribute [rw] title_xml
    #   @return [String, nil] inner XML of the manuscript title
    # @!attribute [rw] xml
    #   @return [String] raw XML of the +MS+ node
    class MS
      # <MS REF="CORP-O"><CITE>155</CITE><LALME>vol. 1. 152. Lincs.</LALME></MS>
      attr_accessor :ref,
        :pref,
        :cite,
        :lalme, :lalme_xml, :lalme_regions,
        :laeme, :laeme_xml, :laeme_regions,
        :title,
        :title_xml,
        :xml

      # Build a new {MS} from a Nokogiri +MS+ element.
      #
      # @param nokonode [Nokogiri::XML::Element, nil] the +MS+ node, or +nil+
      #   to create an empty instance
      def initialize(nokonode = nil)
        return unless nokonode
        @xml = nokonode.to_xml
        @ref = nokonode.attr("REF")
        @pref = case nokonode.attr("PREF")
        when "Y"
          :all
        when "PART"
          :part
        end
        @cite = if (c = nokonode.xpath("CITE").map(&:text).first) && !c.empty?
          c
        end

        l = nokonode.xpath("LALME")
        if !l.empty?
          @lalme = l.map(&:text)
          @lalme_xml = l.map(&:to_xml)
        end
        @lalme_regions = nokonode.xpath("LALME/REGION").map { |x| x.attr("EXPAN") }

        l = nokonode.xpath("LAEME")
        if !l.empty?
          @laeme = l.map(&:text)
          @laeme_xml = l.map(&:to_xml)
        end
        @laeme_regions = nokonode.xpath("LAEME/REGION").map { |x| x.attr("EXPAN") }
      end

      # @return [Boolean] true if this manuscript is the fully preferred witness
      def pref_all?
        @pref == :all
      end

      # @return [Boolean] true if this manuscript is a partially preferred witness
      def pref_part?
        @pref == :part
      end

      # @return [Boolean] true if this manuscript has any preference indicator
      #   (fully or partially preferred)
      def pref_any?
        pref_all? or pref_part?
      end
    end

    # Representable decorator for {MS}. Handles JSON round-tripping.
    # @api private
    class MSRepresenter < Representable::Decorator
      include Representable::JSON

      property :ref
      property :pref
      property :cite

      property :lalme
      property :lalme_xml
      property :lalme_regions

      property :laeme
      property :laeme_xml
      property :laeme_regions

      property :title
      property :title_xml
      property :xml
    end
  end
end
