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

      def display
        if regs.empty?
          orig
        else
          regs.first
        end
      end
    end
  end
end
