require "nokogiri"
require_relative "bib/ms"
require_relative "xml_utilities"
require "representable/json"

# AUTHOR           0    1
# COMMENT          0    1
# E-EDITION        0    9 (children are ED and LINK)
# INDEX            0   57
# INDEXB           0   57
# INDEXC           0    1
# IPMEP            0    3
# JOLLIFFE         0    2
# MSLIST           1    1
# NOTE             0    3 (may contain a STENCIL)
# SEVERS           0   31
# STENCILLIST      1    1
#   -- msgroups
#   -- vargroups
# TITLE            1    1
# WELLS            0    3

module MiddleEnglishDictionary
  # A hyperbib entry -- a full bibliographic record from the MED master
  # bibliography file (+HYPERMED/ENTRY+).
  #
  # The MED maintains a separate bibliography file (the "hyperbib") that
  # contains detailed records for every source cited in the dictionary.
  # {Bib} models one such record, identified by the same +ID+ that appears
  # as the +RID+ attribute on {Entry::Stencil} objects, allowing consumers to
  # join citation stencils with full bibliographic detail.
  #
  # == Construction
  #
  #   bib_set = MiddleEnglishDictionary::Collection::BibSet.new(filename: "hypermed.xml")
  #   bib = bib_set["MED3366"]
  #
  #   # or from a single node:
  #   bib = MiddleEnglishDictionary::Bib.new_from_nokonode(entry_node)
  #
  # == XML pre-processing
  #
  # Before attributes are extracted, {.enclose_tagruns!} wraps runs of +STG+
  # sibling nodes inside +<stglist>+ elements and runs of +SHORTSTENCIL+
  # nodes inside +<shortstencillist>+ elements. This normalises mixed content
  # so that XSLT display stylesheets can iterate over clean lists.
  #
  # @!attribute [rw] id
  #   @return [String] the +ID+ attribute of the +ENTRY+ element
  # @!attribute [rw] title_xml
  #   @return [String] inner XML of the +TITLE+ child (may contain markup)
  # @!attribute [rw] title_text
  #   @return [String] plain-text of the +TITLE+ child
  # @!attribute [rw] incipit
  #   @return [Boolean] true when the +TITLE+ has +TYPE="INCIPIT"+
  # @!attribute [rw] author
  #   @return [String, nil] text of the +AUTHOR+ child, or nil if absent
  # @!attribute [rw] author_sort
  #   @return [String, nil] +SORT+ attribute of the +AUTHOR+ node if present,
  #     otherwise the same as {#author}
  # @!attribute [rw] indexes
  #   @return [Array<String>] text of all +INDEX+ children
  # @!attribute [rw] indexbs
  #   @return [Array<String>] text of all +INDEXB+ children
  # @!attribute [rw] indexcs
  #   @return [Array<String>] text of all +INDEXC+ children
  # @!attribute [rw] ipmeps
  #   @return [Array<String>] text of all +IPMEP+ children
  # @!attribute [rw] jolliffes
  #   @return [Array<String>] text of all +JOLLIFFE+ children
  # @!attribute [rw] severs
  #   @return [Array<String>] text of all +SEVERS+ children
  # @!attribute [rw] wells
  #   @return [Array<String>] text of all +WELLS+ children
  # @!attribute [rw] comment
  #   @return [String, nil] text of the +COMMENT+ child (may contain markup)
  # @!attribute [rw] eedition
  #   @return [Object, nil] reserved for electronic-edition data (+E-EDITION+)
  # @!attribute [rw] notes
  #   @return [Array<String>, nil] notes that may themselves contain stencils
  # @!attribute [rw] hyps
  #   @return [Array<String>] unique +ID+ attributes from all +STENCIL+
  #     descendants (cross-references to other hyperbib entries)
  # @!attribute [rw] manuscripts
  #   @return [Array<Bib::MS>] manuscript references from +MSLIST/MS+ children
  # @!attribute [rw] msgroups
  #   @return [Object, nil] manuscript groups from +STENCILLIST+
  # @!attribute [rw] vargroups
  #   @return [Object, nil] variant groups from +STENCILLIST+
  # @!attribute [rw] xml
  #   @return [String] raw XML of the +ENTRY+ node after tag-run normalization
  class Bib
    # Exactly one
    attr_accessor :title_xml # internal tags
    attr_accessor :title_text
    attr_accessor :incipit

    # 0 or 1
    # attr_accessor :author

    # Any number.
    attr_accessor :id,
      :comment, # might have internal tags
      :eedition, # Tag is E-EDITION; internal structure
      :indexes, :indexbs, :indexcs,
      :ipmeps,
      :jolliffes,
      :notes, # can contain a hyperbib stencil
      :severs,
      :wells,
      :author, # if present in AUTHOR tags
      :author_sort, # either SORT on <AUTHOR> or just the AUTHOR
      :hyps # HYP... ids

    # An MSLIST only contains MS (manuscript) tags, so well just store them
    attr_accessor :manuscripts

    # A StencilList only contains MSGROUPs, and VARGROUPs so just store them
    attr_accessor :msgroups, :vargroups

    # The XML
    attr_accessor :xml

    # Build a new {Bib} from a Nokogiri +HYPERMED/ENTRY+ element.
    #
    # Runs {.enclose_tagruns!} on the node before extraction to normalise
    # mixed content. Raises if the node does not look like a valid entry.
    #
    # @param nokonode [Nokogiri::XML::Element] an +ENTRY+ node from the
    #   hyperbib document
    # @return [Bib] fully populated bibliographic record
    # @raise [RuntimeError] if the node is missing required +TITLE+ or
    #   +STENCILLIST+ children
    def self.new_from_nokonode(nokonode)
      bib = new

      # First, verify that we've got something that looks like an entry
      raise "Node doesn't look like HYPERMED/ENTRY node" unless looks_like_an_entry_node(nokonode)

      # It's a pain in the butt to deal with mixed content. Let's wrap
      # problematic runs of tags so the XSLT is easier.

      enclose_tagruns!(nokonode)

      # nab the transformed
      bib.xml = nokonode.to_xml

      # Get the ID
      bib.id = nokonode.attr("ID")

      # Zero or 1 author
      bib.author = nokonode.xpath("AUTHOR").map(&:text).first

      # Some stuff doesn't have any internal structure, so just grap them

      bib.indexes = nokonode.xpath("INDEX").map(&:text)
      bib.indexbs = nokonode.xpath("INDEXB").map(&:text)
      bib.indexcs = nokonode.xpath("INDEXC").map(&:text)

      bib.ipmeps = nokonode.xpath("IPMEP").map(&:text)
      bib.jolliffes = nokonode.xpath("JOLLIFFE").map(&:text)
      bib.severs = nokonode.xpath("SEVERS").map(&:text)
      bib.wells = nokonode.xpath("WELLS").map(&:text)

      # Hang onto the title xml, since it can have internal tags
      bib.title_xml = nokonode.at("TITLE").inner_html # really  inner_xml in this case
      bib.title_text = nokonode.at("TITLE").text
      bib.incipit = nokonode.at("TITLE").attr("TYPE") == "INCIPIT"

      # Author
      authornode = nokonode.xpath("AUTHOR").first
      if authornode
        bib.author = authornode.text
        bib.author_sort = authornode.attr("SORT") || bib.author
      end

      # Manuscripts
      bib.manuscripts = nokonode.xpath("MSLIST/MS").map { |n| MiddleEnglishDictionary::Bib::MS.new(n) }

      # Linktos
      bib.hyps = nokonode.css("STENCIL").map { |x| x.attr("ID") }.compact.uniq

      bib
    end

    # @return [Boolean] true if the title is an incipit (opening words)
    #   rather than a conventional title
    def incipit?
      @incipit
    end

    # Wrap runs of +STG+ siblings inside +<stglist>+ and runs of
    # +SHORTSTENCIL+ siblings inside +<shortstencillist>+ within the given
    # node, mutating it in place.
    #
    # @param nokonode [Nokogiri::XML::Element] the +ENTRY+ node to transform
    # @return [void]
    def self.enclose_tagruns!(nokonode)
      enc = "<stglist>"
      nokonode.xpath(".//MSGROUP").each do |n|
        MiddleEnglishDictionary::XMLUtilities.enclose_run_of_tags!(node: n, enclosing_node_string: enc, tagname: "STG")
      end

      # Same with VARGROUP/VARIANT/SHORTSTENCIL
      enc = "<shortstencillist>"
      nokonode.xpath(".//VARGROUP/VARIANT").each do |n|
        MiddleEnglishDictionary::XMLUtilities.enclose_run_of_tags!(node: n, enclosing_node_string: enc, tagname: "SHORTSTENCIL")
      end
    end

    # Return true if the node has the structure expected of a +HYPERMED/ENTRY+
    # element (name is "ENTRY" and it has both +TITLE+ and +STENCILLIST+
    # children).
    #
    # @param nokonode [Nokogiri::XML::Element] node to inspect
    # @return [Boolean]
    def self.looks_like_an_entry_node(nokonode)
      nokonode.name == "ENTRY" and
        ["TITLE", "STENCILLIST"] - nokonode.children.map(&:name) == []
    end

    # Serialize this bib and all its sub-objects to JSON.
    #
    # @return [String] JSON representation produced by {BibRepresenter}
    def to_json
      BibRepresenter.new(self).to_json
    end

    # Deserialize a {Bib} from JSON produced by {#to_json}.
    #
    # @param j [String] JSON string
    # @return [Bib] re-hydrated bib record
    def self.from_json(j)
      BibRepresenter.new(new).from_json(j)
    end

    # Read a JSON file and deserialize a {Bib}.
    #
    # @param f [String] path to a file containing bib JSON
    # @return [Bib] re-hydrated bib record
    def self.from_json_file(f)
      from_json(File.open(f, "r:utf-8").read)
    end

    # Representable decorator for {Bib}. Handles JSON round-tripping of the
    # full hyperbib record including its manuscript collection.
    # @api private
    class BibRepresenter < Representable::Decorator
      include Representable::JSON

      property :id

      property :comment
      property :indexes
      property :indexbs
      property :indexcs

      property :ipmeps
      property :jolliffes
      property :wells
      property :severs

      property :xml

      property :author
      property :author_sort

      property :hyps

      property :title_text
      property :title_xml
      property :incipit

      collection :manuscripts,
        decorator: MiddleEnglishDictionary::Bib::MSRepresenter,
        class: MiddleEnglishDictionary::Bib::MS
    end
  end
end
