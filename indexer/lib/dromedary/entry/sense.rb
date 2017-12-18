require 'dromedary/entry/eg'

module Dromedary
  class Entry

    # A "sense" of the word -- a way of using it different enough from
    # other meanings to count as its own thing
    class Sense

      # @return [String] the definition, as an unadorned string
      attr_reader :def


      # The sub-definitions, returned as a hash of the form
      #  {
      #   :initial => Empty string, the whole (unsubbed) definition,
      #               or the 'initial' text before "(a)"
      #   'a' => subdef (a),
      #   'b' => subdef (b),
      #   etc.
      #  }
      # @return [Hash] the initial (or full) text of the definition and subdefs
      attr_reader :subdefs

      # @return [Array<String>] The text of the "usages" (indicating used in
      # the medical community or whatever -- the <USG> tags).
      attr_reader :usages

      # @return [Array<EG>] all the EG objects for this sense
      attr_reader :egs

      # @return [String] the raw XML snippet for this Sense
      attr_reader :xml

      # @param [Nokogiri::XML::Element] nokonode The nokogiri node for this element
      def initialize(nokonode)
        return if nokonode == :empty
        @xml     = nokonode.to_xml
        @def     = nokonode.at('DEF').text
        @subdefs = split_defs(@def)

        @usages = Dromedary.empty_array_on_error do
          nokonode.css('USG').map(&:text).uniq
        end

        @egs = nokonode.css('EG').map {|x| EG.new(x)}

      end

      # A writer, because I want to keep messing with it
      def set_subdefs(def_text = @def)
        @subdefs = split_defs(def_text)
      end

      # We want to split on an '(a)' or the like
      # when preceded by
      #   * the beginning of the string
      #   * a semi-colon or colon followed by whitespace
      DEF_SPLITTER = /(?:\A|(?:[;:]\s+(?:--\s+)?))(\([a-z]\)\s*)/
      DEF_LETTER   = /\(([a-z])\)/

      def split_defs(def_text = @def)
        components  = def_text.chomp('.').split(DEF_SPLITTER)
        initial     = components.shift
        h           = {}
        h[:initial] = initial
        until components.empty?
          m = DEF_LETTER.match components.shift
          raise "Wackiness with definition: #{def_text}" unless m
          letter = m[1]
          subdef = components.shift
          raise "No def after letter" unless subdef
          h[letter] = subdef
        end
        h
      end
    end
  end
end
