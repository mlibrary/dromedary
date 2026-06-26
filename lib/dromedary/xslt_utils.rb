require_relative "smart_xml"
require "annoying_utilities"

module Dromedary
  module XSLTUtils
    module Class
      DEFAULT_XSL_DIR = AnnoyingUtilities.xslt_dir

      CACHED_XSL = {}

      # Loads (and in production, caches) an XSLT stylesheet by basename.
      # In non-production environments the stylesheet is re-read from disk on every call.
      # @param basename [String] filename of the XSL file (e.g. +"Entry.xsl"+)
      # @param xdir [Pathname] directory containing the XSL file (default: +indexer/xslt/+)
      # @return [Nokogiri::XSLT] the compiled XSLT object
      def load_xslt(basename, xdir = DEFAULT_XSL_DIR)
        return CACHED_XSL[basename] if CACHED_XSL[basename]
        xsl = Nokogiri::XSLT(File.open(xdir + basename, "r:utf-8").read)
        if ENV["RAILS_ENV"] == "production"
          CACHED_XSL[basename] = xsl
        end
        xsl
      end
    end

    module Instance
      ####### XSLT Transform helpers #####

      # Create a document from the given node, or nil if nil was passed
      # @param [Nokogiri::XML::Node] node The node to document-ify
      # @return [Nokgiri::XML::Document] A document containing nothing but that node
      def doc_from_node(node)
        return nil if node.nil?
        return node.dup if node.document?
        doc = Nokogiri::XML::Document.new
        doc.add_child node.dup
        doc
      end

      # We need to pass a full XML document node (not just an element) to
      # the XSLT transform, so we make one here.
      #
      # Given an xpath, find the first corresponding node in the @entry
      # nokonode and turn it into a free-standing document that contains
      # only that node
      # @param [String] xpath The xpath in the @entry nokonode (starting with '/ENTRY')
      # @return [Nokogiri::XML::Document, nil] The created nokogiri document, or nil if not found
      def doc_from_xpath(xpath)
        doc_from_node(@nokonode.xpath(xpath).first)
      end

      # Given a nokogiri node, turn it into a document (if it isn't already)
      # and apply the provided XSLT transformation.
      # @param node [Nokogiri::XML::Node] the XML node to transform
      # @param xslt [Nokogiri::XSLT] the XSLT object used to do the transformation
      # @param params [Array] optional XSLT parameters passed to +apply_to+
      # @return [String, nil] the transformed text (usually HTML), or +nil+ if +node+ is +nil+
      def xsl_transform_from_node(node, xslt, params = [])
        return nil if node.nil?
        _xml = xslt.apply_to(doc_from_node(node), params)
      end

      # Parses a raw XML string and applies the given XSLT transformation to it.
      # @param xml [String, nil] raw XML string, or +nil+
      # @param xslt [Nokogiri::XSLT] the XSLT object used to do the transformation
      # @param params [Array] optional XSLT parameters passed to +apply_to+
      # @return [String, nil] the transformed text (usually HTML), or +nil+ if +xml+ is +nil+
      def xsl_transform_from_xml(xml, xslt, params = [])
        return nil if xml.nil?
        xsl_transform_from_node(Nokogiri::XML(xml), xslt, params)
      end
    end
  end
end
