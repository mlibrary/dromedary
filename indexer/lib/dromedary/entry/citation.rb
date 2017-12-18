require 'dromedary/entry/bib'
require 'dromedary/entry/quote'

module Dromedary
  class Entry

    # An individual citation always has a bib entry and a quote. It may
    # also have integer-ized guesses at the years the work was created
    # (cd) and the year this particular manuscript is from (md)
    class Citation

      # @return [Quote] The quotation object for this citataion
      attr_reader :quote

      # @return [Integer] the year the work was originally created (written)
      attr_reader :cd

      # @return [Integer] the year of this specific manuscript
      attr_reader :md

      # @return [Bib] The Bib object for this citation
      attr_reader :bib

      # @param [Nokogiri::XML::Element] nokonode The nokogiri node for this element
      def initialize(nokonode)
        @md    = nokonode.attr('MD') && nokonode.attr('MD').to_i
        @cd    = nokonode.attr('CD') && nokonode.attr('CD').to_i
        @quote = Quote.new(nokonode.at('Q'))
        @bib   = Bib.new(nokonode.at('BIBL'))

      end

    end
  end
end
