require "nokogiri"
require "middle_english_dictionary/utilities"
require "middle_english_dictionary/external_dictionary_link"
require "middle_english_dictionary/collection/hash_array"
require "pathname"

module MiddleEnglishDictionary
  module Collection
    # Base class for OED and DOE cross-reference link collections.
    #
    # Parses an XML file of the form:
    #
    #   <links>
    #     <link sourceID="MED003366" targetID="id1#id2#id3">
    #       <!-- subclass-specific term elements -->
    #     </link>
    #     ...
    #   </links>
    #
    # Each +link+ element is read and, if its +sourceID+ starts with +"MED"+,
    # an {ExternalDictionaryLink} is built and stored keyed by the normalized
    # MED ID. Links whose +targetID+ contains only empty or invalid entries
    # (containing +---+) are silently discarded. A warning is printed to stdout
    # when a duplicate MED ID is encountered.
    #
    # Subclasses must implement {#get_terms} and {#get_normalized_term} to
    # extract the dictionary-specific heading nodes.
    #
    # @see OEDLinkSet
    # @see DOELinkSet
    class ExternalDictionaryLinkSet < HashArray
      # Parse +/links/link+ nodes from a Nokogiri document and return a new
      # link set.
      #
      # @param nokonode [Nokogiri::XML::Document] parsed links XML document
      # @return [ExternalDictionaryLinkSet] populated link set
      def self.from_nokonode(nokonode)
        nokonode.xpath("/links/link").each_with_object(new) do |linknode, new_set|
          raw_med_id = linknode.attr("sourceID")
          next unless raw_med_id.to_s.start_with?("MED")

          med_id = MiddleEnglishDictionary.normalize_med_id(raw_med_id)
          target_ids_string = linknode.attr("targetID")
          target_terms = new_set.get_terms(linknode)
          normalized = new_set.get_normalized_term(linknode)

          link = MiddleEnglishDictionary::ExternalDictionaryLink.new(med_id: med_id, normalized_term: normalized)
          link.add_valid_terms!(ids_string: target_ids_string, terms: target_terms)

          unless link.empty?
            puts "Huh. Already have something in it for id #{med_id}" if new_set[med_id]
            new_set[med_id] = link
          end
        end
      end

      # Extract the display terms for this link from the link node.
      #
      # Must be overridden in each subclass to select the correct child elements
      # (e.g. +oedHed+ or +doeHed+).
      #
      # @abstract
      # @param nokonode [Nokogiri::XML::Element] a +link+ element
      # @return [Array<String>] ordered list of term strings
      # @raise [RuntimeError] always -- must be overridden
      def get_normalized_term(nokonode)
        raise "Override in subclass"
      end

      # Return the normalized display form for the linked entry.
      #
      # Must be overridden in each subclass.
      #
      # @abstract
      # @param nokonode [Nokogiri::XML::Element] a +link+ element
      # @return [String, nil] normalized term string, or +nil+
      # @raise [RuntimeError] always -- must be overridden
      def get_terms(nokonode)
        raise "Override in subclass"
      end

      # Parse links from raw XML string.
      #
      # @param xml [String] XML source
      # @return [ExternalDictionaryLinkSet] populated link set
      def self.from_xml(xml)
        from_nokonode(Nokogiri::XML(xml))
      end

      # Parse links from an XML file.
      #
      # The file is read as ISO-8859-1 and re-encoded to UTF-8 before parsing.
      #
      # @param filename [String] path to the XML file
      # @return [ExternalDictionaryLinkSet] populated link set
      def self.from_xml_file(filename)
        xml = File.read(filename).encode("UTF-8", "ISO-8859-1")
        from_xml(xml)
      end
    end

    # An {ExternalDictionaryLinkSet} for Oxford English Dictionary cross-references.
    #
    # Reads +oedHed+ child nodes from each link for terms and uses the +norm+
    # child node as the normalized term.
    class OEDLinkSet < ExternalDictionaryLinkSet
      # @param nokonode [Nokogiri::XML::Element] a +link+ element
      # @return [Array<String>] text of all +oedHed+ children
      def get_terms(nokonode)
        nokonode.xpath("oedHed").map(&:text)
      end

      # @param nokonode [Nokogiri::XML::Element] a +link+ element
      # @return [String, nil] text of the +norm+ child, or +nil+ if absent
      def get_normalized_term(nokonode)
        norm_node = nokonode.at("norm")
        norm_node&.text
      end
    end

    # An {ExternalDictionaryLinkSet} for Dictionary of Old English cross-references.
    #
    # Reads +doeHed+ child nodes from each link for terms; uses the last term
    # as the normalized form.
    class DOELinkSet < ExternalDictionaryLinkSet
      # @param nokonode [Nokogiri::XML::Element] a +link+ element
      # @return [Array<String>] text of all +doeHed+ children
      def get_terms(nokonode)
        nokonode.xpath("doeHed").map(&:text)
      end

      # @param nokonode [Nokogiri::XML::Element] a +link+ element
      # @return [String, nil] the last +doeHed+ term as the normalized form
      def get_normalized_term(nokonode)
        get_terms(nokonode).last
      end
    end
  end
end
