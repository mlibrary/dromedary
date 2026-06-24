require_relative "sense"
require_relative "class_methods"
require "representable/json"

module MiddleEnglishDictionary
  class Entry
    # A group of related senses, corresponding to the +SENSEGRP+ XML element.
    #
    # A sense group clusters two or more {Sense} objects that share a common
    # broad meaning. The group itself may carry a definition (+DEF+ child) and
    # always has a group number (+N+ attribute) that is propagated to each
    # child {Sense#sensegrp_number}.
    #
    # @!attribute [rw] definition_xml
    #   @return [String] XML of all +DEF+ child nodes joined with newlines
    # @!attribute [rw] definition_text
    #   @return [String] plain-text of all +DEF+ child nodes joined with newlines
    # @!attribute [rw] sensegrp_number
    #   @return [String, nil] value of the +N+ attribute on the +SENSEGRP+ node
    # @!attribute [rw] senses
    #   @return [Array<Sense>] senses contained within this group; each has
    #     its {Sense#sensegrp_number} set to this group's number
    # @!attribute [rw] xml
    #   @return [String] raw XML of the +SENSEGRP+ node
    # @!attribute [rw] entry_id
    #   @return [String, nil] ID of the owning {Entry}
    class SenseGrp
      extend Entry::ClassMethods

      attr_accessor :definition_xml, :definition_text, :sensegrp_number, :senses, :xml, :entry_id

      # Build a new {SenseGrp} from a Nokogiri +SENSEGRP+ element.
      #
      # Sets {Sense#sensegrp_number} on every child sense to this group's
      # number after construction.
      #
      # @param nokonode [Nokogiri::XML::Element] the +SENSEGRP+ node
      # @param entry_id [String, nil] ID of the owning entry
      # @return [SenseGrp] new instance populated from the node
      def self.new_from_nokonode(nokonode, entry_id: nil)
        sensegrp = new
        sensegrp.entry_id = entry_id
        sensegrp.xml = nokonode.to_xml
        sensegrp.sensegrp_number = nokonode.attr("N")
        sensegrp.definition_xml = nokonode.xpath("DEF").map(&:to_xml).join("\n")
        sensegrp.definition_text = nokonode.xpath("DEF").map(&:text).join("\n")
        sensegrp.senses = nokonode.xpath("SENSE").map { |s| Entry::Sense.new_from_nokonode(s, entry_id: entry_id) }
        sensegrp.senses.each { |s| s.sensegrp_number = sensegrp.sensegrp_number }
        sensegrp
      end
    end

    # Representable decorator for {SenseGrp}. Handles JSON round-tripping.
    #
    # Stores +objclass+ so that the mixed-type {Entry#sensestuff} array can be
    # re-hydrated to the correct class on deserialization.
    # @api private
    class SenseGrpRepresenter < Representable::Decorator
      include Representable::JSON

      # Representable is weird in that it doesn't support mixed-class arrays
      # in an easy way. Have to do some messing around, including storing the
      # class of the object in the representation (json, in our case). It's
      # ignored (via `skip_class`) when parsing back into an object from the
      # json.
      property :objclass, getter: ->(represented:, **) { represented.class.to_s }, skip_parse: true

      property :entry_id
      property :xml
      property :definition_xml
      property :definition_text
      property :sensegrp_number
      collection :senses, decorator: Entry::SenseRepresenter, class: Entry::Sense
    end
  end
end
