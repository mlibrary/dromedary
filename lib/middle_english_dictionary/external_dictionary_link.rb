require "nokogiri"
require "representable/json"
require "middle_english_dictionary/utilities"

##
#
# <link sourceID="MED03366" targetID="14189">
#   <medHed>babanliche, adv.</medHed>
#   <oedHed>baban, n.</oedHed>
#   <oedSub type="derivative">babanly</oedSub>
#   <norm>babanly</norm>
# </link>
##

module MiddleEnglishDictionary
  # A cross-reference target from a MED entry to an entry in an external
  # dictionary (OED or DOE).
  #
  # @!attribute [r] med_id
  #   @return [String, nil] normalized MED identifier (e.g. "MED3366")
  # @!attribute [rw] normalized_term
  #   @return [String, nil] canonical display form of the linked term
  # @!attribute [rw] targets
  #   @return [Array<LinkTarget>] individual cross-reference targets
  LinkTarget = Struct.new(:med_id, :target_id, :term)

  # A collection of cross-references from one MED entry to one or more entries
  # in an external dictionary (OED or DOE).
  #
  # Each instance is +Enumerable+ over its {targets} array.
  #
  # @example Building a link manually
  #   link = ExternalDictionaryLink.new(med_id: "MED003366", normalized_term: "babanly")
  #   link.add_valid_terms!(ids_string: "14189#14190", terms: ["baban, n.", "babanly"])
  #   link.targets.size #=> 2
  class ExternalDictionaryLink
    include Enumerable

    attr_accessor :targets, :normalized_term
    attr_reader :med_id

    # @param med_id [String, nil] raw or normalized MED identifier
    # @param normalized_term [String, nil] canonical display form
    def initialize(med_id: nil, normalized_term: nil)
      @med_id = med_id if med_id
      @normalized_term = normalized_term if normalized_term
      @targets = []
    end

    # Iterate over each {LinkTarget} in {targets}.
    #
    # @yield [target] each cross-reference target
    # @yieldparam target [LinkTarget]
    # @return [Enumerator] if no block is given
    def each
      return enum_for :each unless block_given?
      @targets.each { |x| yield x }
    end

    # Set the MED identifier, normalizing leading zeros.
    #
    # @param raw_val [String, nil] raw MED ID (e.g. "MED003366")
    # @return [String, nil] normalized MED ID, or nil if +raw_val+ is nil
    def med_id=(raw_val)
      raw_val ? MiddleEnglishDictionary.normalize_med_id(raw_val) : nil
    end

    # Parse a "#"-delimited string of target IDs and pair each with the
    # corresponding term, appending valid pairs to {targets}. Entries whose
    # ID contains "---" (placeholder/missing) are silently skipped.
    #
    # @param ids_string [String] "#"-delimited target IDs, e.g. "14189#14190"
    # @param terms [Array<String>] display terms parallel to the IDs
    # @return [self, nil] returns +self+ after adding targets, or +nil+ if
    #   either argument is empty
    def add_valid_terms!(ids_string:, terms: [])
      ids = ids_string.split("#").map(&:strip)

      return if terms.empty?
      return if ids.empty?

      ids.zip(terms).each do |id, term|
        next if /---/.match?(id)
        @targets << LinkTarget.new(med_id, id, term)
      end

      self
    end

    # @return [Boolean] true if no valid cross-reference targets have been added
    def empty?
      @targets.empty?
    end
  end

  # Representable decorator for {LinkTarget}. Handles JSON round-tripping of
  # individual cross-reference target structs.
  # @api private
  class LinkTargetRepresenter < Representable::Decorator
    include Representable::JSON
    property :med_id
    property :target_id
    property :term
  end

  # Representable decorator for {ExternalDictionaryLink}. Handles JSON
  # round-tripping of a full external dictionary cross-reference, including its
  # collection of {LinkTarget} objects.
  # @api private
  class ExternalDictionaryLinkRepresenter < Representable::Decorator
    include Representable::JSON
    property :med_id
    property :normalized_term
    collection :targets, decorator: LinkTargetRepresenter, class: LinkTarget
  end
end
