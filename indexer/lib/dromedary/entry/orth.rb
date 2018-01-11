module Dromedary
  class Entry
    class Orth

      # @return [String] the original formulation of the word
      attr_reader :orig

      # @return [Array<String>] the regularized versions of the word
      attr_reader :regs

      def initialize(nokonode)
        @orig = nokonode.at('ORIG').text
        @regs = nokonode.xpath('REG').map(&:text)
      end

      def all_forms
        [@orig] +  @regs
      end

      def display
        if regs.empty?
          orig
        else
          regs.first
        end
      end

      def to_h
        {
          orig: orig,
          regs: regs
        }
      end

      def self.from_h(h)
        obj = allocate
        obj.fill_from_hash(h)
        obj
      end

      def fill_from_hash(h)
        @orig = h[:orig]
        @regs = h[:regs]
      end



    end
  end
end
