module Dromedary
  class Entry
    # A Stencil is a a bibliographic reference. Here we pull
    # out, if there are any, highlighted phrases, the title, and the
    # non-parsed date.
    #
    # We also have the "rid", a unique identifier used to cross-reference
    # to the hyperbib
    class Stencil

      attr_reader :rid, :date, :highlighted_phrases, :title

      def initialize(nokonode)
        @rid = nokonode.attr('RID')
        (@date = nokonode.at('DATE')) and (@date = @date.text)
        @highlighted_phrases = nokonode.css('HI').map(&:text).uniq
        (@title = nokonode.at('TITLE')) and (@title = @title.text)
      end

      def to_h
        {
            rid: rid,
            date: date,
            highlighted_phrases: highlighted_phrases,
            title: title
        }
      end

      def self.from_h(h)
        obj = allocate
        obj.fill_from_hash(h)
        obj
      end

      private
      def fill_from_hash(h)
        @rid = h[:rid]
        @date = h[:date]
        @highlighted_phrases = h[:highlighted_phrases]
        @title = h[:title]

      end

    end
  end
end
