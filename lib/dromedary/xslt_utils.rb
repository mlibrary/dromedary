require_relative "smart_xml"
require "annoying_utilities"

module Dromedary
  module XSLTUtils
    module Class
      DEFAULT_XSL_DIR = AnnoyingUtilities.xslt_dir

      CACHED_XSL = {}

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
      # and apply the provided xslt transformation
      # @param [String] xpath The xpath into the entry (root is '/ENTRYFREE')
      # @param [Nokogiri::XSLT] xslt The XSLT object used to do the transformation
      # @return [String,nil] The transfored text (usualy html), or nil if the xpath not found
      def xsl_transform_from_node(node, xslt, params = [])
        return nil if node.nil?
        _xml = xslt.apply_to(doc_from_node(node), params)
      end

      # Given an XML snippet or nil, and an xslt object, return
      # the transformation (or nil if the snippet was nil)
      # @param [String,nil] xml The raw XML string, or nil
      # @param [Nokogiri::XSLT] xslt The XSLT object used to do the transformation
      # @return [String,nil] The transfored text (usualy html), or nil if the xpath not found
      def xsl_transform_from_xml(xml, xslt, params = [])
        return nil if xml.nil?
        xsl_transform_from_node(Nokogiri::XML(xml), xslt, params)
      end
    end
  end
end
