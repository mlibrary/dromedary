module Dromedary
  class SmartXML
    def initialize(xml)
      @xml = xml
    end

    def to_s
      @xml
    end

    def truncate(n)
      HTML_Truncator.truncate(@xml, n, length_in_chars: true)
    end
  end
end
