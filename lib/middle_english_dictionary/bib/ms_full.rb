module MiddleEnglishDictionary
  class Bib
    # A full manuscript title record, sourced from +HYPERMED/MSLIB/MSFULL+
    # nodes in the hyperbib XML.
    #
    # {MSFull} objects are created by {Collection::MSNames} and looked up
    # via the manuscript +REF+ code to resolve the short sigla stored on
    # {MS#ref} into human-readable titles.
    #
    # @!attribute [rw] code
    #   @return [String, nil] short manuscript code (e.g. +"CORP-O"+), matching
    #     the +MS+ attribute on the +MSFULL+ element
    # @!attribute [rw] title
    #   @return [String, nil] plain-text title of the manuscript, stripped of
    #     leading/trailing whitespace
    # @!attribute [rw] title_xml
    #   @return [String, nil] inner XML of the +MSFULL+ element, preserving any
    #     inline markup
    class MSFull
      attr_accessor :code, :title, :title_xml

      # @param code [String, nil] manuscript code
      # @param title [String, nil] plain-text title
      # @param title_xml [String, nil] inner XML of the title
      def initialize(code = nil, title = nil, title_xml = nil)
        @code = code
        @title = title
        @title_xml = title_xml
      end
    end
  end
end
