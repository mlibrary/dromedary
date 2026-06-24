require "middle_english_dictionary/entry/class_methods"
require "nokogiri"
require "middle_english_dictionary/xml_utilities"
require "middle_english_dictionary/entry/orth"
require "middle_english_dictionary/entry/sense"
require "middle_english_dictionary/entry/sensegrp"
require "middle_english_dictionary/entry/note"
require "middle_english_dictionary/entry/supplement"
require "middle_english_dictionary/external_dictionary_link"
require "representable/json"

module MiddleEnglishDictionary
  # A single dictionary entry from the Middle English Dictionary.
  #
  # An +Entry+ corresponds to one +<ENTRYFREE>+ element within a +<MED>+
  # document. It models the complete linguistic record for a headword,
  # including all orthographic forms, part-of-speech information, etymology,
  # ordered senses/notes/supplements, and citations.
  #
  # == Constructing an entry
  #
  # Use the class-level factory methods rather than +new+:
  #
  #   entry = MiddleEnglishDictionary::Entry.new_from_xml_file("MED003366.xml")
  #   entry = MiddleEnglishDictionary::Entry.new_from_xml(xml_string)
  #   entry = MiddleEnglishDictionary::Entry.from_json(json_string)
  #
  # == Spelling forms
  #
  # The MED distinguishes *headwords* (+HDORTH+) from additional variant forms
  # (+ORTH+), and within each it distinguishes the original diplomatic spelling
  # (+ORIG+) from the regularized spelling (+REG+). The convenience methods
  # {#all_forms}, {#original_headwords}, {#regularized_headwords}, etc. expose
  # these at various levels of granularity.
  #
  # == Sense structure
  #
  # {#senses} provides a flat list of every +SENSE+ node anywhere in the entry.
  # {#sensestuff} provides the document-order hierarchy of
  # +SENSE+ / +SENSEGRP+ / +NOTE+ / +SUPPLEMENT+ elements directly under the
  # entry root, preserving nesting for display purposes.
  #
  # @!attribute [rw] id
  #   @return [String] the +ID+ attribute of the +ENTRYFREE+ element
  # @!attribute [rw] sequence
  #   @return [Integer] the +SEQ+ attribute, used to order entries alphabetically
  # @!attribute [rw] source
  #   @return [String, Symbol] basename of the source file, or +:io+ if parsed
  #     from a string
  # @!attribute [rw] xml
  #   @return [String] raw XML of the +ENTRYFREE+ element
  # @!attribute [rw] headwords
  #   @return [Array<Orth>] headword forms from +FORM/HDORTH+ nodes
  # @!attribute [rw] orths
  #   @return [Array<Orth>] additional orthographic forms from +FORM/ORTH+ nodes
  # @!attribute [rw] pos
  #   @return [String] part-of-speech text from +FORM/POS+
  # @!attribute [rw] pos_facet
  #   @return [Array<String>] expanded POS facet values from
  #     +FORM/POS/PS/@EXPAN+
  # @!attribute [rw] etym_xml
  #   @return [String, nil] raw XML of the +ETYM+ node, or nil if absent
  # @!attribute [rw] etym_text
  #   @return [String, nil] plain-text content of the +ETYM+ node, or nil if
  #     absent
  # @!attribute [rw] etym_languages
  #   @return [Array<String>] expanded language names from +ETYM/LANG/LG/@EXPAN+
  # @!attribute [rw] senses
  #   @return [Array<Sense>] all +SENSE+ nodes anywhere in the entry, flattened
  # @!attribute [rw] sensestuff
  #   @return [Array<Sense, SenseGrp, Note, Supplement>] document-order list of
  #     structural elements directly under the entry root
  # @!attribute [rw] supplements
  #   @return [Array<Supplement>] top-level +SUPPLEMENT+ nodes
  # @!attribute [rw] notes
  #   @return [Array<String>] plain-text of top-level +NOTE+ nodes,
  #     whitespace-normalized
  # @!attribute [rw] oedlinks
  #   @return [ExternalDictionaryLink, nil] cross-references to the OED
  # @!attribute [rw] doelinks
  #   @return [ExternalDictionaryLink, nil] cross-references to the DOE
  class Entry
    # Recursive helper that walks +SENSE|SENSEGRP|NOTE|SUPPLEMENT+ children of
    # any node and returns them as an ordered array of model objects. Used to
    # populate {Entry#sensestuff} and {Sense#sensestuff}.
    module SenseStuffHierarchy
      # Build a document-order array of model objects from the direct
      # +SENSE+/+SENSEGRP+/+NOTE+/+SUPPLEMENT+ children of +nokonode+.
      #
      # @param entry_id [String, nil] ID of the owning entry, threaded down to
      #   each child object
      # @param nokonode [Nokogiri::XML::Element] node whose children are walked
      # @return [Array<Sense, SenseGrp, Note, Supplement>] ordered child objects
      # @raise [RuntimeError] if an unexpected element name is encountered
      def self.sense_hierarchy(entry_id, nokonode)
        nokonode.xpath(ENTRY_XPATHS[:sense_stuff]).map do |n|
          case n.name
          when "SENSEGRP"
            SenseGrp.new_from_nokonode(n, entry_id: entry_id)
          when "SENSE"
            Sense.new_from_nokonode(n, entry_id: entry_id)
          when "NOTE"
            Note.new_from_nokonode(n, entry_id: entry_id)
          when "SUPPLEMENT"
            Supplement.new_from_nokonode(n, entry_id: entry_id)
          else
            raise "Shouldn't be getting a #{n.name} in sensestuff array"
          end
        end
      end
    end

    # extend MiddleEnglishDictionary::Entry::SenseStuff
    extend Entry::ClassMethods

    # XPath expressions used to locate the root entry node.
    ROOT_XPATHS = {
      entry: "/MED/ENTRYFREE"
    }.freeze

    # XPath expressions used to extract sub-elements of an +ENTRYFREE+ node.
    ENTRY_XPATHS = {
      hdorth: "FORM/HDORTH",
      other_orth: "FORM/ORTH",
      pos_facet: "FORM/POS/PS/@EXPAN",
      pos: "FORM/POS",
      etym: "ETYM",
      etym_languages: "ETYM/LANG/LG/@EXPAN",
      sense: "SENSE",
      sense_anywhere: "//SENSE",
      sensegrp: "SENSEGRP",
      sense_stuff: "SENSE|SENSEGRP|NOTE|SUPPLEMENT"
    }.freeze

    attr_accessor :headwords
    attr_accessor :source
    attr_accessor :id
    attr_accessor :sequence
    attr_accessor :orths
    attr_accessor :xml
    attr_accessor :etym_xml
    attr_accessor :etym_text
    attr_accessor :etym_languages
    attr_accessor :pos
    attr_accessor :pos_facet
    attr_accessor :senses
    attr_accessor :notes
    attr_accessor :supplements
    attr_accessor :oedlinks
    attr_accessor :doelinks

    # The "right" way to do this with Representable is...well, I'm not sure
    # what it is. I'm just going to recreate it from the raw XML every time
    # I read it, because while it's strikingly inefficient and makes me want
    # to shower, it'll work and it's good enough for now. See
    # def sensestuff, below

    attr_accessor :sensestuff

    # Build a new {Entry} from a Nokogiri document node rooted at +<MED>+.
    #
    # All element names in the subtree are uppercased before parsing to
    # normalise case-inconsistent source XML.
    #
    # @param root_nokonode [Nokogiri::XML::Document, Nokogiri::XML::Element]
    #   document or element node wrapping the +<MED><ENTRYFREE>+ structure
    # @param source [String, nil] source label (typically a filename) stored on
    #   the resulting entry
    # @return [Entry] fully populated entry
    def self.new_from_nokonode(root_nokonode, source: nil)
      MiddleEnglishDictionary::XMLUtilities.case_raise_all_tags!(root_nokonode)

      entry_nokonode = root_nokonode.at(ROOT_XPATHS[:entry])

      entry = new
      entry.source = source ? Pathname.new(source).basename : :io
      entry.xml = entry_nokonode.to_xml

      entry.id = entry_nokonode.attr("ID")
      entry.sequence = entry_nokonode.attr("SEQ").to_i

      entry.headwords = entry.derive_headwords(entry_nokonode)
      entry.orths = entry.derive_orths(entry_nokonode)

      if (etym_node = entry_nokonode.at(ENTRY_XPATHS[:etym]))
        entry.etym_xml = etym_node.to_xml
        entry.etym_text = etym_node.text
      end

      entry.etym_languages = entry_nokonode.xpath(ENTRY_XPATHS[:etym_languages]).map(&:value)

      entry.pos = entry_nokonode.at(ENTRY_XPATHS[:pos]).text
      entry.pos_facet = entry_nokonode.xpath(ENTRY_XPATHS[:pos_facet]).map(&:value)

      entry.senses = entry_nokonode.xpath(ENTRY_XPATHS[:sense_anywhere]).map { |sense| Sense.new_from_nokonode(sense, entry_id: entry.id) }
      entry.supplements = entry_nokonode.xpath("SUPPLEMENT").map { |supp| Supplement.new_from_nokonode(supp, entry_id: entry.id) }

      entry.notes = entry_nokonode.xpath("NOTE").map(&:text).map { |x| x.gsub(/[\s\n]+/, " ") }.map(&:strip)

      # We want a set of all the sensegrp / sense / note stuff in one list, so they can be
      # displayed in order using XSLT. The data are *not* consistent enough to be able
      # to do it programmatically in a straightforward way.
      #

      entry.sensestuff = SenseStuffHierarchy.sense_hierarchy(entry.id, entry_nokonode)
      entry
    end

    # Return a pretty-printed, indented XML string for this entry.
    #
    # @return [String] nicely formatted XML of the whole entry
    def pretty_xml
      MiddleEnglishDictionary::XMLUtilities.pretty_xml(xml)
    end

    # Getting headwords and forms

    # The "original" (diplomatic) spelling(s) of the headword(s) as they
    # appear in the paper dictionary.
    #
    # @return [Array<String>] unique original headword spellings
    def original_headwords
      headwords.flat_map(&:origs).uniq
    end

    # Regularized spelling(s) of the headword(s), with no extra punctuation.
    #
    # @return [Array<String>] regularized headword spellings
    def regularized_headwords
      headwords.flat_map(&:regs)
    end

    # All given spellings (original and regularized) of the headword(s).
    #
    # @return [Array<String>] unique combined headword spellings
    def all_headword_forms
      headwords.flat_map(&:all_forms).uniq
    end

    # Original presentation of the non-headword orthographic variant form(s).
    #
    # @return [Array<String>] unique original orth spellings
    def original_orths
      orths.flat_map(&:origs).uniq
    end

    # Regularized presentation of the non-headword orthographic variant form(s).
    #
    # @return [Array<String>] regularized orth spellings
    def regularized_orths
      orths.flat_map(&:regs)
    end

    # All given spellings (original and regularized) of the non-headword
    # orthographic forms.
    #
    # @return [Array<String>] unique combined orth spellings
    def all_orth_forms
      orths.flat_map(&:all_forms).uniq
    end

    # All original spellings across headwords and orth variants.
    #
    # @return [Array<String>] unique combined original forms
    def all_original_forms
      original_headwords.concat(original_orths).uniq
    end

    # All regularized spellings across headwords and orth variants.
    #
    # @return [Array<String>] unique combined regularized forms
    def all_regularized_forms
      regularized_headwords.concat(regularized_orths).uniq
    end

    # All given spellings (original and regularized) for this entry.
    #
    # @return [Array<String>] unique combined forms from headwords and orths
    def all_forms
      all_original_forms.concat(all_regularized_forms).uniq
    end

    # @private
    def derive_headwords(entry_nokonode)
      entry_nokonode.xpath(ENTRY_XPATHS[:hdorth]).map { |w| Entry::Orth.new_from_nokonode(w, entry_id: id) }
    end

    # @private
    def derive_orths(entry_nokonode)
      entry_nokonode.xpath(ENTRY_XPATHS[:other_orth]).map { |w| Entry::Orth.new_from_nokonode(w, entry_id: id) }
    end

    # All citations in the entry, drawn from both senses and supplements.
    #
    # @return [Array<Citation>] flat list of all citations
    def all_citations
      [senses, supplements].flatten.flat_map(&:egs).flat_map(&:citations)
    end

    # All citation-level bibliographic references in the entry.
    #
    # @return [Array<Bib>] flat list of all {Bib} objects from all citations
    def all_bibs
      all_citations.map(&:bib)
    end

    # All quoted passages in the entry.
    #
    # @return [Array<Quote>] flat list of all {Quote} objects from all citations
    def all_quotes
      all_citations.map(&:quote)
    end

    # All bibliographic stencils in the entry. A stencil is the structured
    # citation proper: title, date, manuscript reference, etc.
    #
    # @return [Array<Stencil>] flat list of all {Stencil} objects from all bibs
    def all_stencils
      all_bibs.map(&:stencil)
    end

    # Serialize this entry and all its sub-objects to JSON.
    #
    # @return [String] JSON representation produced by {EntryRepresenter}
    def to_json
      EntryRepresenter.new(self).to_json
    end

    # Deserialize an {Entry} from JSON produced by {#to_json}.
    #
    # @param j [String] JSON string
    # @return [Entry] re-hydrated entry
    def self.from_json(j)
      EntryRepresenter.new(new).from_json(j)
    end

    # Read a JSON file from disk and deserialize an {Entry}.
    #
    # @param f [String] path to a file containing entry JSON
    # @return [Entry] re-hydrated entry
    def self.from_json_file(f)
      from_json(File.open(f, "r:utf-8").read)
    end
  end

  # Representable decorator for {Entry}. Handles JSON round-tripping of the
  # complete entry object graph.
  #
  # The mixed-type {Entry#sensestuff} collection is handled by dynamically
  # selecting the appropriate decorator and re-hydration class based on the
  # stored +objclass+ property in each JSON fragment.
  # @api private
  class EntryRepresenter < Representable::Decorator
    include Representable::JSON

    # Lambda that maps a Ruby class to its +*Representer+ decorator class.
    DECORATOR_FOR_CLASS = ->(klass) do
      Kernel.const_get(klass.to_s + "Representer")
    end

    property :id
    property :source
    property :sequence
    property :xml
    property :etym_xml
    property :etym_text
    property :etym_languages

    property :pos
    property :pos_facet

    property :oedlinks, decorator: MiddleEnglishDictionary::ExternalDictionaryLinkRepresenter, class: MiddleEnglishDictionary::ExternalDictionaryLink
    property :doelinks, decorator: MiddleEnglishDictionary::ExternalDictionaryLinkRepresenter, class: MiddleEnglishDictionary::ExternalDictionaryLink

    property :notes

    collection :headwords, decorator: Entry::OrthRepresenter, class: Entry::Orth
    collection :orths, decorator: Entry::OrthRepresenter, class: Entry::Orth
    collection :senses, decorator: Entry::SenseRepresenter, class: Entry::Sense
    collection :supplements, decorator: Entry::SupplementRepresenter, class: Entry::Supplement

    # Representable is weird in that it doesn't support mixed-class arrays
    # in an easy way. Here, we choose the decorator based on the class + 'Representer',
    # and the parsed-into class based on the stored 'objclass' property of
    # the json representation
    collection :sensestuff,
      decorator: ->(options) { DECORATOR_FOR_CLASS.call(options[:input].class) },
      class: ->(options) do
        begin
          Kernel.const_get options[:fragment]["objclass"]
        rescue => e
          require "pry"
          binding.pry
        end
      end
  end
end
