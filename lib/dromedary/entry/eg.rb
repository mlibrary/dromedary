require_relative "citation"

module Dromedary
  class Entry

    # EG == "Example Given" a set of related citations. Entries often
    # have more than one EG section, one for each sub-definition.
    class EG

      # @return [Array<Citation>] The citations for this set of examples
      attr_reader :citations

      # @return [String, nil] The sub-definition this set of citations refers to
      attr_reader :subdef_entry

      # @param [Nokogiri::XML::Element] nokonode The nokogiri node for this element
      def initialize(nokonode)
        return if nokonode == :empty
        @citations    = nokonode.xpath('CIT').map {|x| Citation.new(x)}
        @subdef_entry = nokonode.attribute('N') && nokonode.attribute('N').value.downcase
      end

      def to_h
        {
            citations: citations.map(&:to_h),
            subdef_entry: subdef_entry
        }
      end

      def self.from_h(h)
        obj = allocate
        obj.fill_from_hash(h)
        obj
      end

      def fill_from_hash(h)
        @citations = h[:citations].map{|x| Citation.from_h(x)}
        @subdef_entry = h[:subdef_entry]
      end

    end
  end
end
