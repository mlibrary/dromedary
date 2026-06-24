require "middle_english_dictionary/entry/class_methods"
require_relative "eg"
require "representable/json"

module MiddleEnglishDictionary
  class Entry
    # A single dictionary sense, corresponding to the +SENSE+ XML element.
    #
    # A sense contains one or more definitions ({#definition_text},
    # {#definition_xml}) and illustrative example groups ({#egs}). Senses may
    # be nested inside a {SenseGrp}; when that is the case, {#sensegrp_number}
    # carries the parent group's identifier.
    #
    # {#sensestuff} provides a document-order list of any nested
    # +SENSE+/+SENSEGRP+/+NOTE+/+SUPPLEMENT+ nodes found directly inside this
    # sense, mirroring the structure used on {Entry#sensestuff}.
    #
    # @!attribute [rw] xml
    #   @return [String] raw XML of the +SENSE+ node
    # @!attribute [rw] definition_xml
    #   @return [String] XML of all +DEF+ child nodes joined with newlines
    # @!attribute [rw] definition_text
    #   @return [String] plain-text of all +DEF+ child nodes joined with newlines
    # @!attribute [rw] discipline_usages
    #   @return [Array<String>] capitalized +EXPAN+ values from
    #     +DEF/USG[@TYPE="FIELD"]+ nodes (e.g. "Law", "Medicine")
    # @!attribute [rw] grammatical_usages
    #   @return [Array<String>] grammatical usage labels (reserved; not yet
    #     populated)
    # @!attribute [rw] egs
    #   @return [Array<EG>] example groups contained in this sense
    # @!attribute [rw] sense_number
    #   @return [String] value of the +N+ attribute on the +SENSE+ node,
    #     defaulting to +"1"+ if absent
    # @!attribute [rw] sensegrp_number
    #   @return [String, nil] +N+ attribute of the enclosing {SenseGrp}, or nil
    #     if this sense is not inside a sense group
    # @!attribute [rw] notes
    #   @return [Array<String>] note text strings from +NOTE+ child nodes,
    #     whitespace-normalized
    # @!attribute [rw] sensestuff
    #   @return [Array<Sense, SenseGrp, Note, Supplement>] ordered list of
    #     nested structural elements within this sense
    # @!attribute [rw] entry_id
    #   @return [String, nil] ID of the owning {Entry}
    class Sense
      extend Entry::ClassMethods

      attr_accessor :xml, :definition_xml, :definition_text,
        :discipline_usages, :grammatical_usages,
        :egs, :sense_number, :entry_id, :notes,
        :sensegrp_number, :sensestuff

      # Build a new {Sense} from a Nokogiri +SENSE+ element.
      #
      # @param nokonode [Nokogiri::XML::Element] the +SENSE+ node
      # @param entry_id [String, nil] ID of the owning entry
      # @return [Sense] new instance populated from the node
      def self.new_from_nokonode(nokonode, entry_id: nil)
        sense = new
        sense.xml = nokonode.to_xml
        sense.definition_xml = nokonode.xpath("DEF").map(&:to_xml).join("\n")
        sense.definition_text = nokonode.xpath("DEF").map(&:text).join("\n")
        sense.sense_number = (nokonode.attr("N") || 1).to_s

        sense.entry_id = entry_id
        sense.discipline_usages = sense.get_discipline_usages(nokonode)

        sense.egs = nokonode.css("EG").map { |eg| EG.new_from_nokonode(eg, entry_id: entry_id) }

        sense.notes = nokonode.xpath("NOTE").map(&:text).map { |x| x.gsub(/[\s\n]+/, " ") }.map(&:strip)

        # We'll make a list of all the "sense" things (stuff that appears within a SENSE or
        # SENSEGRP) so we can provide them to the display in the correct order.
        #
        sense.sensestuff = SenseStuffHierarchy.sense_hierarchy(entry_id, nokonode)

        sense
      end

      # Extract field/discipline usage labels from +DEF/USG[@TYPE="FIELD"]/@EXPAN+
      # attributes within the given node.
      #
      # @param nokonode [Nokogiri::XML::Element] the node to search within
      # @return [Array<String>] unique, capitalized field labels
      def get_discipline_usages(nokonode)
        nokonode.xpath('//DEF/USG[@TYPE="FIELD"]/@EXPAN').map(&:value).map(&:capitalize).uniq
      end
    end

    # Representable decorator for {Sense}. Handles JSON round-tripping.
    #
    # Stores +objclass+ so that the mixed-type {Entry#sensestuff} array can be
    # re-hydrated to the correct class on deserialization.
    # @api private
    class SenseRepresenter < Representable::Decorator
      include Representable::JSON

      # Representable is weird in that it doesn't support mixed-class arrays
      # in an easy way. Have to do some messing around, including storing the
      # class of the object in the representation (json, in our case). It's
      # ignored (via `skip_class`) when parsing back into an object from the
      # json.

      property :objclass, getter: ->(represented:, **) { represented.class.to_s }, skip_parse: true

      property :entry_id
      property :definition_xml
      property :definition_text
      property :sense_number
      property :sensegrp_number
      property :discipline_usages
      collection :egs, decorator: EGRepresenter, class: EG
      property :notes
    end
  end
end
