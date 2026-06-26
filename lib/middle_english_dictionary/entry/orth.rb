require "middle_english_dictionary/entry/class_methods"
require "representable/json"

module MiddleEnglishDictionary
  class Entry
    # A single orthographic form of a MED headword or variant spelling.
    #
    # Each +Orth+ wraps the +HDORTH+ or +ORTH+ XML element and exposes both
    # the original (diplomatic) spellings from +ORIG+ child nodes and the
    # regularized spellings from +REG+ child nodes.
    #
    # @!attribute [rw] regs
    #   @return [Array<String>] regularized spelling(s) from +REG+ child nodes
    # @!attribute [rw] origs
    #   @return [Array<String>] original (diplomatic) spelling(s) from +ORIG+ child nodes
    # @!attribute [rw] entry_id
    #   @return [String, nil] ID of the owning {Entry}
    # @!attribute [rw] notes
    #   @return [Array<String>] note text strings attached to this orth node
    class Orth
      extend Entry::ClassMethods

      attr_accessor :regs, :origs, :entry_id, :notes

      # @param regs [Array<String>] regularized spellings
      # @param origs [Array<String>] original spellings
      # @param entry_id [String, nil] ID of the owning entry
      # @param notes [Array<String>] note text strings
      def initialize(regs: [], origs: [], entry_id: nil, notes: [])
        @entry_id = entry_id
        @regs = regs
        @origs = origs
      end

      # All spellings (original and regularized), deduplicated.
      #
      # @return [Array<String>] combined unique list of {origs} and {regs}
      def all_forms
        origs.concat(regs).uniq
      end

      # Build a new {Orth} from a Nokogiri element representing an +HDORTH+
      # or +ORTH+ XML node.
      #
      # @param nokonode [Nokogiri::XML::Element] the +HDORTH+ or +ORTH+ node
      # @param entry_id [String, nil] ID of the owning entry
      # @return [Orth] new instance populated from the node
      def self.new_from_nokonode(nokonode, entry_id: nil)
        regs = nokonode.xpath("REG").map(&:text)
        origs = nokonode.xpath("ORIG").map(&:text)
        notes = nokonode.xpath("NOTE").map(&:text).map { |x| x.gsub(/[\s\n]+/, " ") }.map(&:strip)
        new(regs: regs, origs: origs, entry_id: entry_id, notes: notes)
      end
    end

    # Representable decorator for {Orth}. Handles JSON round-tripping.
    # @api private
    class OrthRepresenter < Representable::Decorator
      include Representable::JSON

      property :entry_id
      property :regs
      property :origs
      property :notes
    end
  end
end
