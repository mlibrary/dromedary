require 'dromedary/entry/stencil'
module Dromedary
  class Entry
    # A Bib is just a stencil. Stored as a unit because we need to hang onto
    # the XML
    class Bib

      attr_reader :stencil, :xml

      def initialize(nokonode)
        stencil_node = nokonode.at('STNCL')
        @stencil = Stencil.new(stencil_node) if stencil_node
        @xml      = nokonode.to_xml
      end

      def to_h
        {
            stencil: stencil.to_h,
            xml: xml
        }
      end

      def self.from_h(h)
        obj = allocate
        obj.fill_from_hash(h)
        obj
      end

      def fill_from_hash(h)
        @stencil = Stencil.from_h(h[:stencil])
        @xml = h[:xml]
      end
    end
  end
end
