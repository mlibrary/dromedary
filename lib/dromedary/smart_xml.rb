module Dromedary
# Thin wrapper around an XML string that adds a character-count truncation helper.
# @note No references to +SmartXML+ found in the codebase — may be unused.
class SmartXML
  # @param xml [String] raw XML string
  def initialize(xml)
    @xml = xml
  end

  # @return [String] the raw XML string
  def to_s
    @xml
  end

  # Truncates the XML to at most +n+ characters using +HTML_Truncator+,
  # preserving valid markup.
  # @param n [Integer] maximum character length
  # @return [String] the truncated XML/HTML string
  def truncate(n)
      HTML_Truncator.truncate(@xml, n, length_in_chars: true)
    end
  end
end
