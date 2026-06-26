require "representable/json"
require_relative "class_methods"

module MiddleEnglishDictionary
  class Entry
    # A note attached to an entry, sense, or sense group, represented as an
    # object so that it can be included in the ordered {Entry#sensestuff} /
    # {Sense#sensestuff} arrays alongside {Sense}, {SenseGrp}, and {Supplement}
    # objects.
    #
    # The +NOTE+ XML element has no structural sub-elements beyond plain text,
    # so this class is intentionally minimal.
    #
    # @!attribute [rw] text
    #   @return [String, nil] whitespace-normalized text content of the +NOTE+
    #     node
    # @!attribute [rw] xml
    #   @return [String] raw XML of the +NOTE+ node
    # @!attribute [rw] entry_id
    #   @return [String, nil] ID of the owning {Entry}
    class Note
      extend Entry::ClassMethods

      attr_accessor :text, :xml, :entry_id

      # Build a new {Note} from a Nokogiri +NOTE+ element.
      #
      # @param nokonode [Nokogiri::XML::Element] the +NOTE+ node
      # @param entry_id [String, nil] ID of the owning entry
      # @return [Note] new instance populated from the node
      def self.new_from_nokonode(nokonode, entry_id: nil)
        note = new
        note.entry_id = entry_id
        note.text = nokonode.map(&:text).map { |x| x.gsub(/[\s\n]+/, " ") }.map(&:strip).first
        note.xml = nokonode.to_xml
        note
      end
    end

    # Representable decorator for {Note}. Handles JSON round-tripping.
    #
    # Stores +objclass+ so that the mixed-type {Entry#sensestuff} array can be
    # re-hydrated to the correct class on deserialization.
    # @api private
    class NoteRepresenter < Representable::Decorator
      include Representable::JSON

      property :objclass, getter: ->(represented:, **) { represented.class.to_s }, skip_parse: true

      property :entry_id
      property :xml
      property :text
    end
  end
end
