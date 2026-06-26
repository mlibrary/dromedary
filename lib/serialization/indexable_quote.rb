require "annoying_utilities"
require "middle_english_dictionary"

module Dromedary # standard:disable Lint/Syntax
  # Flat, indexable representation of a single MED citation (quote + bibliographic metadata).
  # Built from a {MiddleEnglishDictionary::Entry::Citation} and used to produce
  # Solr documents during indexing.
  #
  # The XSLT transform converts the raw quote XML into HTML at construction time
  # so it is available as +quote_html+ without further processing.
  #
  # Attribute schema (all are read/write via +attr_accessor+):
  # - +quote+ — plain-text quote string
  # - +quote_html+ — HTML-rendered quote (via XSLT)
  # - +entry_id+ — MED entry ID (e.g. +"MED1234"+); aliased as +med_id+
  # - +cd+ / +md+ — creation date / manuscript date as integers
  # - +date+ — human-readable date string
  # - +scope+ — page/folio reference from the bib stencil
  # - +rid+ / +title+ / +author+ / +ms+ — stencil fields
  # - +bib_id+, +stencil_author+, +stencil_title+, +dubious+, +citation+, +headword+, +pos+
  class IndexableQuote
    XSLT = Nokogiri::XSLT(File.read(AnnoyingUtilities::DROMEDARY_ROOT + "indexer" + "xslt" + "Common.xsl"))

    attr_accessor :quote, :quote_html, :text,
      :date,
      :entry_id, :headword, :pos,
      :cd, :md,
      :scope, :rid, :title, :ms,
      :citation,
      :author,
      :bib_id, :stencil_author, :stencil_title,
      :dubious,
      :entry

    alias_method :med_id, :entry_id

    # @param citation [MiddleEnglishDictionary::Entry::Citation] the citation to build from
    def initialize(citation:)
      self.quote = citation.quote.text
      self.entry_id = citation.entry_id
      self.cd = citation.cd
      self.md = citation.md
      quote_node = Nokogiri::XML(citation.quote.xml)
      self.quote_html = XSLT.transform(quote_node).to_html.chomp
      self.scope = citation.bib.scope

      stencil = citation.bib.stencil
      self.rid = stencil.rid
      self.date = stencil.date
      self.title = stencil.title
      self.author = stencil.author
      self.stencil_title = stencil.title
      self.stencil_author = stencil.author
      self.ms = stencil.ms
      self.citation = citation
      self.text = citation.text
    end
    # standard:enable Lint/Syntax

    # Provide a JSON representation of this object and all its sub-objects
    # @return [String] json for this object
    def to_json
      IndexableQuoteRepresenter.new(self).to_json
    end
  end

  # Representable::Decorator that serialises an {IndexableQuote} to JSON.
  #
  # Maps each declared +property+ to the matching +attr_accessor+ on the
  # decorated {IndexableQuote} object.  The nested +citation+ property is
  # delegated to +MiddleEnglishDictionary::Entry::CitationRepresenter+ for
  # deep serialisation.
  #
  # @note +stencil_author+ and +stencil_title+ are set on {IndexableQuote} at
  #   construction time but are intentionally absent from this representer;
  #   they duplicate +author+ and +title+ and are not needed in the JSON output.
  class IndexableQuoteRepresenter < Representable::Decorator  # standard:disable Lint/Syntax
    include Representable::JSON

    property :quote

    property :entry_id
    property :headword
    property :pos
    property :bib_id
    property :author
    property :cd
    property :md
    property :quote_html
    property :scope
    property :rid
    property :date
    property :title
    property :ms
    property :citation, decorator: MiddleEnglishDictionary::Entry::CitationRepresenter, class: MiddleEnglishDictionary::Entry::Citation
  end
end
