require "nokogiri"

module MiddleEnglishDictionary
  # Utility methods for manipulating Nokogiri XML documents used throughout
  # the MED parsing pipeline.
  module XMLUtilities
    # Inspect min and max child-node counts for each unique child element name
    # across all nodes matched by +xpath+. Useful for schema analysis.
    #
    # @param doc [Nokogiri::XML::Document] the document to inspect
    # @param xpath [String] XPath expression selecting the parent nodes
    # @return [Hash{String => Array(Integer, Integer)}] a hash mapping each
    #   child element name to +[min_count, max_count]+, sorted by name
    def self.arities(doc, xpath)
      h = Hash.new { |h, k| h[k] = {} }

      nodes = doc.xpath(xpath)

      kids = nodes.flat_map(&:children).flat_map(&:name).uniq - ["text"]

      kids.each do |k|
        nodes.each do |x|
          h[k][x.xpath(k).count] = true
        end
      end

      h.keys.sort.each_with_object({}) do |k, acc|
        arities = h[k].keys
        acc[k] = [arities.min, arities.max]
      end
    end

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

    # Return a pretty-printed, indented XML string by applying an internal
    # XSLT stylesheet that normalises whitespace and adds consistent indentation.
    #
    # @param xml [String] raw XML string to format
    # @return [String] indented, human-readable XML
    def self.pretty_xml(xml)
      PrettyXSL.apply_to(Nokogiri::XML(xml)).to_s
    end

    PrettyXSLSS = <<~EOXSL # rubocop:disable Naming/ConstantName
      <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
        <xsl:output method="xml" indent="yes" omit-xml-declaration="yes" encoding="UTF-8"/>
        <xsl:param name="indent-increment" select="'   '"/>
        <xsl:template name="newline">
          <xsl:text disable-output-escaping="yes">
      </xsl:text>
        </xsl:template>
        <xsl:template match="comment() | processing-instruction()">
          <xsl:param name="indent" select="''"/>
          <xsl:call-template name="newline"/>
          <xsl:value-of select="$indent"/>
          <xsl:copy />
        </xsl:template>
        <xsl:template match="text()">
          <xsl:param name="indent" select="''"/>
          <xsl:call-template name="newline"/>
          <xsl:value-of select="$indent"/>
          <xsl:value-of select="normalize-space(.)"/>
        </xsl:template>
        <xsl:template match="text()[normalize-space(.)='']"/>
        <xsl:template match="*">
          <xsl:param name="indent" select="''"/>
          <xsl:call-template name="newline"/>
          <xsl:value-of select="$indent"/>
            <xsl:choose>
             <xsl:when test="count(child::*) > 0">
              <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates select="*|text()">
                 <xsl:with-param name="indent" select="concat ($indent, $indent-increment)"/>
               </xsl:apply-templates>
               <xsl:call-template name="newline"/>
               <xsl:value-of select="$indent"/>
              </xsl:copy>
             </xsl:when>
             <xsl:otherwise>
              <xsl:copy-of select="."/>
             </xsl:otherwise>
           </xsl:choose>
        </xsl:template>
      </xsl:stylesheet>
    EOXSL

    # Compiled XSLT stylesheet used by {.pretty_xml}.
    PrettyXSL = Nokogiri::XSLT(PrettyXSLSS)
  end
end
