require 'annoying_utilities'
require 'middle_english_dictionary'

module Dromedary
  # For quotes, a record is a simple structure
  #   quote: <string>
  #   entry_id: "MED..."
  #   cd: date_of_creation.to_i,
  #   md: date_of_manuscript.to_i
  #   date: the actual date string
  #   quote_html: html of the quote <string>,
  #   rid: rid for this stencil
  #   title: title of the stencil
  #   manuscript_abbrev: manuscript abbreviation thing
  #   scope: the "scope" (page number-lik things)
  class IndexableQuote

    XSLT = Nokogiri::XSLT(File.read(AnnoyingUtilities::DROMEDARY_ROOT + 'indexer' + 'xslt' + 'Common.xsl'))

    attr_accessor :quote, :quote_html, :text,
                  :date,
                  :entry_id, :headword, :pos,
                  :cd, :md,
                  :scope, :rid, :title, :ms,
                  :citation,
                  :author, :title,
                  :bib_id, :stencil_author, :stencil_title,
                  :dubious

    alias_method :med_id, :entry_id

    def initialize(citation: citation)
      self.quote      = citation.quote.text
      self.entry_id   = citation.entry_id
      self.cd         = citation.cd
      self.md         = citation.md
      quote_node = Nokogiri::XML(citation.quote.xml)
      self.quote_html = XSLT.transform(quote_node).to_html.chomp
      self.scope      = citation.bib.scope

      stencil       = citation.bib.stencil
      self.rid      = stencil.rid
      self.date     = stencil.date
      self.title    = stencil.title
      self.author   = stencil.author
      self.stencil_title = stencil.title
      self.stencil_author = stencil.author
      self.ms       = stencil.ms
      self.citation = citation
      self.text = citation.text
    end

    # Provide a JSON representation of this object and all its sub-objects
    # @return [String] json for this object
    def to_json
      IndexableQuoteRepresenter.new(self).to_json
    end

  end

  class IndexableQuoteRepresenter < Representable::Decorator
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
