require "nokogiri"

module MiddleEnglishDictionary
  # Utility methods for manipulating Nokogiri XML documents used throughout
  # the MED parsing pipeline.
  module XMLUtilities
    # Wrap each contiguous run of sibling elements named +tagname+ inside a
    # new wrapper element, mutating the document in place. Whitespace-only text
    # nodes between matching siblings are treated as transparent. This
    # normalizes mixed content so that XSLT stylesheets can iterate over a
    # clean list rather than scattered siblings.
    #
    # @param node [Nokogiri::XML::Node] the parent node whose children are scanned
    # @param enclosing_node_string [String] XML string for the wrapper element,
    #   e.g. +"<stglist>"+ (Nokogiri will auto-close it)
    # @param tagname [String] local element name to group, e.g. +"STG"+
    # @return [void]
    def self.enclose_run_of_tags!(node:, enclosing_node_string:, tagname:)
      iter = node.children.select { |x| !x.text? or x.text =~ /\S/ }.enum_for(:each)
      loop do
        n = iter.next
        if n.name == tagname
          y = n.add_previous_sibling(enclosing_node_string).first
          while n.name == tagname
            n.parent = y
            n = iter.next
          end
        end
      end
    end

    # Uppercase every element name in the subtree rooted at +node+, mutating
    # the document in place. Used to normalise case-inconsistent source XML
    # before XPath queries that rely on uppercase tag names.
    #
    # @param node [Nokogiri::XML::Node] root of the subtree to transform
    # @return [nil]
    def self.case_raise_all_tags!(node)
      node.traverse { |node| node.name = node.name.upcase if node.instance_of?(Nokogiri::XML::Element) }
      nil
    end

  end
end
