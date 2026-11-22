require "nokogiri"
require "delegate"
require "middle_english_dictionary/bib/ms_full"

module MiddleEnglishDictionary
  module Collection
    # A lookup table mapping manuscript codes to {Bib::MSFull} records.
    #
    # {MSNames} is a thin +SimpleDelegator+ wrapping a plain +Hash+, so all
    # standard hash methods (+[]+ , +each+, +key?+, etc.) work directly on the
    # instance. It is used by {BibSet#add_ms_full_titles!} to resolve the short
    # manuscript siglum stored on {Bib::MS#ref} into a full title.
    #
    class MSNames < SimpleDelegator
      # Create an empty {MSNames} instance backed by a new hash.
      def initialize
        @ms = {}
        __setobj__(@ms)
      end

      # Build an {MSNames} lookup table from +HYPERMED/MSLIB/MSFULL+ elements
      # in a Nokogiri document.
      #
      # Each +MSFULL+ element's +MS+ attribute becomes the key; the text
      # content (stripped) becomes {Bib::MSFull#title} and the raw inner XML
      # becomes {Bib::MSFull#title_xml}.
      #
      # @param nokonode [Nokogiri::XML::Document] the hyperbib document
      # @return [MSNames] populated lookup table
      def self.new_from_nokonode(nokonode)
        msnames = new
        nokonode.xpath("HYPERMED/MSLIB/MSFULL").each do |ms|
          code = ms.attr("MS")
          title = ms.text.strip
          title_xml = ms.inner_html # actually XML
          msnames[code] = MiddleEnglishDictionary::Bib::MSFull.new(code, title, title_xml)
        end
        msnames
      end

    end
  end
end
