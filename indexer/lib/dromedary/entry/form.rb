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

      # @return [Array<String>] The words in all the ORTH tags, stripped to be text
      attr_reader :orths

      # @return [Array<String>] The words from the N1, N2, ... attributes in the ORTHs
      attr_reader :orth_alts

      # @return [Array<String>] The headwords
      attr_reader :headwords

      # @param [Nokogiri::XML::Element] nokonode The nokogiri node for this element
      def initialize(nokonode)
        return if nokonode == :empty
        @pos       = (nokonode.at('POS') and nokonode.at('POS').text.strip) # need to translate?
        @headwords = self.find_headwords(nokonode)
        @orths     = nokonode.xpath('ORTH').map(&:text).reject {|x| x.empty?}
        @orth_alts = nokonode.xpath('ORTH').flat_map do |o|
          o.attributes.select {|k, v| k =~ /\AN\d+/}.values.map(&:value)
        end
      end


      # Extract the headwords from the nokogiri node
      # @!visibility private
      def find_headwords(nokonode)
        headwords = []
        nokonode.xpath('(POS|ORTH)').each do |n|
          break if n.name == 'POS'
          headwords << n.text
        end
        headwords
      end


    end
  end
end
