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
    end
  end
end
