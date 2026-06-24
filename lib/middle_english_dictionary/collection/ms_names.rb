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
    # @example
    #   names = MSNames.new_from_xml_file("hypermed.xml")
    #   names["CORP-O"].title  #=> "Oxford, Corpus Christi ..."
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

      # Parse the hyperbib XML from a file and build an {MSNames} lookup table.
      #
      # @param filename [String] path to the hyperbib XML file (UTF-8)
      # @return [MSNames] populated lookup table
      def self.new_from_xml_file(filename)
        new_from_nokonode(Nokogiri::XML(File.open(filename, "r:utf-8").read))
      end
    end
  end
end
