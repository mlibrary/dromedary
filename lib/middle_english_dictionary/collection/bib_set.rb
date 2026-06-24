require "nokogiri"
require_relative "../bib"
require_relative "ms_names"

module MiddleEnglishDictionary
  module Collection
    # An +Enumerable+ collection of {Bib} objects parsed from a MED hyperbib
    # XML file (+HYPERMED/ENTRY+ nodes), keyed by bib ID.
    #
    # After all {Bib} records are built, {#add_ms_full_titles!} is called
    # automatically to resolve the short manuscript codes stored on each
    # {Bib::MS#ref} into full titles via a {MSNames} lookup.
    #
    # @example
    #   bibs = BibSet.new(filename: "/data/med/hypermed.xml")
    #   bibs["STENCIL-ID"].title_text  #=> "Piers Plowman"
    #   bibs.map(&:author).compact     #=> ["Chaucer, Geoffrey", ...]
    class BibSet
      include Enumerable

      # Parse the hyperbib XML document and build the collection.
      #
      # Exactly one of +filename+ or +nokonode+ must be provided.
      #
      # @param filename [String, nil] path to the hyperbib XML file
      # @param nokonode [Nokogiri::XML::Document, nil] already-parsed document
      # @raise [RuntimeError] if neither +filename+ nor +nokonode+ is given
      def initialize(filename: nil, nokonode: nil)
        raise "Need to provide either a filename or a nokonode" unless filename || nokonode

        nokonode ||= Nokogiri::XML(File.open(filename, "r:utf-8").read)

        # Run one: make all the bibs
        @bibs = nokonode.xpath("/HYPERMED/ENTRY").each_with_object({}) do |n, h|
          b = MiddleEnglishDictionary::Bib.new_from_nokonode(n)
          h[b.id] = b
        end

        add_ms_full_titles!(nokonode)
      end

      # Iterate over each {Bib} value in the collection.
      #
      # @yield [bib] each {Bib} record
      # @return [Enumerator] if no block is given
      def each
        return enum_for(:each) unless block_given?
        @bibs.each_pair do |k, v|
          yield v
        end
      end

      # Iterate over each +[id, bib]+ pair in the collection.
      #
      # @yield [pair] a two-element array +[id, bib]+
      # @return [Enumerator] if no block is given
      def each_pair
        return enum_for(:each) unless block_given?
        @bibs.each_pair do |k, v|
          yield [k, v]
        end
      end

      # Retrieve the {Bib} with the given ID.
      #
      # @param k [String] bib ID
      # @return [Bib, nil] the matching bib, or +nil+ if not found
      def [](k)
        @bibs[k]
      end

      # Resolve manuscript codes on every {Bib::MS} in the collection by
      # looking up {Bib::MS#ref} in a {MSNames} index built from the same
      # document.
      #
      # Sets both {Bib::MS#title} and {Bib::MS#title_xml} in place.
      #
      # @param nokonode [Nokogiri::XML::Document] the hyperbib document,
      #   which must contain +HYPERMED/MSLIB/MSFULL+ nodes
      # @return [void]
      def add_ms_full_titles!(nokonode)
        names = MSNames.new_from_nokonode(nokonode)
        each do |b|
          b.manuscripts.each do |ms|
            ms.title = names[ms.ref].title
            ms.title_xml = names[ms.ref].title_xml
          end
        end
      end
    end
  end
end
