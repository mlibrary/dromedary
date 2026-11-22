module Dromedary
  # Thin wrapper around transformed HTML with character-count truncation.
  class SmartXML
    # @param xml [String] raw XML string
    def initialize(xml)
      @xml = xml
    end

    # @return [String] the raw XML string
    def to_s
      @xml
    end

    # Truncates HTML while preserving valid markup.
    # @param n [Integer] maximum character length
    # @return [String] the truncated HTML string
    def truncate(n)
      HTML_Truncator.truncate(@xml, n, length_in_chars: true)
    end
  end
end
