module Dromedary
  class Entry

    # A Quote can have a bunch of parts, almost all of them optional. At its
    # core, though, it's just a string of text with some inline markup that
    # we may or may not want to worry about
    #
    # All the attributes are just (often empty) arrays of text strings marked
    # up with the given tag
    class Quote
      attr_reader :titles
      attr_reader :added
      attr_reader :ovars
      attr_reader :highlighted_phrases
      attr_reader :text
      attr_reader :xml

      def initialize(nokonode)
        @titles              = Dromedary.empty_array_on_error {nokonode.css("TITLE").map(&:text)}.uniq
        @added               = Dromedary.empty_array_on_error {nokonode.css("ADDED").map(&:text)}.uniq
        @ovars               = Dromedary.empty_array_on_error {nokonode.css("OVARS").map(&:text)}.uniq
        @highlighted_phrases = Dromedary.empty_array_on_error {nokonode.css("HI").map(&:text)}.uniq
        @text                = nokonode.text
        @xml                 = nokonode.to_xml
      end

      def to_h
        {
            titles: titles,
            added: added,
            ovars: ovars,
            highlighted_phrases: highlighted_phrases,
            text: text,
            xml: xml
        }
      end

      def self.from_h(h)
        obj = allocate
        obj.fill_from_hash(h)
        obj
      end

      def fill_from_hash(h)
        @titles = h[:titles]
        @added = h[:added]
        @ovars = h[:ovars]
        @highlighted_phrases = h[:highlighted_phrases]
        @text = h[:text]
        @xml = h[:xml]
      end

    end
  end
end

