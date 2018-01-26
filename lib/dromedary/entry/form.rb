require_relative "orth"

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


      # @return [String] The first regularized entry for the headword
      attr_reader :display_word

      # @param [Nokogiri::XML::Element] nokonode The nokogiri node for this element
      def initialize(nokonode)
        return if nokonode == :empty
        @pos        = nokonode.at('POS') and nokonode.xpath('POS').map(&:text).map(&:strip).compact # need to translate?
        hdorth_node = nokonode.at('HDORTH')
        orth_nodes  = nokonode.xpath('ORTH').select {|x| !x.text.strip.empty?}
        if hdorth_node
          @headword = Orth.new(hdorth_node)
        else
          if orth_nodes.size > 0
            @headword = Orth.new(orth_nodes.first)
          end
        end
        @orths        = orth_nodes.map {|orthnode| Orth.new(orthnode)}
      end

      def display_word
        if @headword.regs.empty?
          @headword.orig
        else
          pick_best_display_word
        end
      end

      # Not sure if this is a good way to go or not,
      # but it's here if we want it.
      def pick_best_display_word(headword = self.headword)
        if headword.orig =~ /[(?]/
          headword.regs.first
        else
          headword.orig
        end
      end

      def normalized_pos(pos = self.pos)
        pos.downcase.gsub(/\s*\(\d\)\s*\Z/, '').gsub(/\.+\s*\Z/, '').gsub(/\./, ' ')
      end

      def to_h
        {
          pos:          pos,
          orths:        orths.map(&:to_h),
          headword:     headword.to_h,
        }
      end

      def self.from_h(h)
        obj = allocate
        obj.fill_from_hash(h)
        obj
      end

      def fill_from_hash(h)
        @pos          = h[:pos]
        @orths        = h[:orths].map {|x| Orth.from_h(x)}
        @headword     = Orth.from_h(h[:headword])
      end

    end
  end
end
