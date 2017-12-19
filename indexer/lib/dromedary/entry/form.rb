require 'dromedary/entry/orth'

module Dromedary
  class Entry

    # The Form has a bunch of ways of representing the word. It has (probably)
    # several Orths; each of which is a "word". Some orths are "headwords", the
    # most important variants.
    #
    # Some Orths have alternate spellings; these are combined across orth
    # entries in #orth_alts, because I can't imagine why we'd use them
    # except for indexing.
    class Form

      # @return [String] the unaltered part of speech
      attr_reader :pos


      # @return [Array<Orth>] The words in all the ORTH tags, stripped to be text
      attr_reader :orths


      # @return [Orth] The headword
      attr_reader :headword

      # @param [Nokogiri::XML::Element] nokonode The nokogiri node for this element
      def initialize(nokonode)
        return if nokonode == :empty
        @pos       = (nokonode.at('POS') and nokonode.at('POS').text.strip) # need to translate?
        @headword  = Orth.new(nokonode.at('HDORTH'))
        @orths     = nokonode.xpath('/ORTH').map{|orthnode| Orth.new(orthnode)}
      end

    end
  end
end
