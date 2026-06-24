require "middle_english_dictionary/errors"

module MiddleEnglishDictionary
  class Entry
    # Class-level factory methods shared by {Entry} and {Orth} for constructing
    # objects from raw XML strings or files.
    module ClassMethods
      # Parse an XML string and return a new instance.
      #
      # @param xml [String] XML content representing a MED entry or orthographic
      #   form; must be well-formed
      # @param source [String, nil] optional label used to identify the source
      #   in error messages (e.g. a filename)
      # @return [Entry, Orth] a new instance built from the parsed XML
      # @raise [MiddleEnglishDictionary::InvalidXML] if +xml+ is not well-formed
      def new_from_xml(xml, source: nil)
        _node = Nokogiri::XML(xml) { |conf| conf.strict }
        new_from_nokonode(Nokogiri::XML(xml), source: source)
      rescue Nokogiri::XML::SyntaxError => e
        raise MiddleEnglishDictionary::InvalidXML.new("Invalid XML in #{source}: #{e.message}")
      end

      # Read a file from disk and parse it as XML, returning a new instance.
      #
      # @param filename [String] path to the XML file
      # @return [Entry, Orth] a new instance built from the file's XML content
      # @raise [MiddleEnglishDictionary::FileNotFound] if +filename+ does not exist
      # @raise [MiddleEnglishDictionary::FileEmpty] if +filename+ is empty
      # @raise [MiddleEnglishDictionary::InvalidXML] if the file's content is
      #   not well-formed XML
      def new_from_xml_file(filename)
        raise MiddleEnglishDictionary::FileNotFound.new("File '#{filename}' not found") unless File.exist?(filename)
        raise MiddleEnglishDictionary::FileEmpty.new("File '#{filename}' is empty") if File.empty?(filename)
        new_from_xml(File.open(filename, "r:utf-8").read, source: filename)
      end
    end
  end
end
