require 'middle_english_dictionary'
require 'securerandom'

$LOAD_PATH.unshift Pathname.new(__dir__).parent + 'lib'
require 'annoying_utilities'
require 'med_installer'

settings do
  store "log.batch_size", 2_500
  provide 'med.data_dir', Pathname(__dir__).parent.parent + 'data'
  provide "reader_class_name", 'MedInstaller::Traject::EntryJsonReader'
end


# Do a terrible disservice to traject and monkeypatch it to take
# our existing logger

Traject::Indexer.send(:define_method, :logger, ->() {AnnoyingUtilities.logger})


# For quotes, a record is a simple struct
#   quote: <string>
#   entry_id: "MED..."
#   cd: date_of_creation.to_i,
#   md: date_of_manuscript.to_i
#   quote_html: html of the quote <string>,
#   rid: rid for this stencil
#   title: title of the stencil
#   manuscript: manuscript abbreviation thing

def lazy_method(name)
  ->(rec, acc) {acc.replace Array(rec.send(name))}
end

to_field 'type' do |q, acc|
  acc << 'quote'
end

to_field 'id' do |q, acc|
  acc << SecureRandom.uuid
end

to_field 'entry_id', lazy_method(:entry_id)


to_field 'quote_text', lazy_method(:quote)
to_field 'quote_html', lazy_method(:quote_html)

to_field 'cd', lazy_method(:cd)
to_field 'md', lazy_method(:md)

to_field 'rid', lazy_method(:rid)
to_field "quote_manuscript", lazy_method(:ms)
to_field "quote_date", lazy_method(:date)
to_field "scope", lazy_method(:scope)

to_field("citation_json") do |q, acc|
  acc << q.citation.to_json
end



# def initialize(citation: citation)
#   self.quote      = citation.quote.text
#   self.entry_id   = citation.entry_id
#   self.cd         = citation.cd
#   self.md         = citation.md
#   self.quote_html = XSLT.apply_to(Nokogiri::XML(citation.quote.xml))
#   self.scope      = citation.bib.scope
#
#   stencil                = citation.bib.stencil
#   self.rid               = stencil.rid
#   self.date              = stencil.date
#   self.title             = stencil.title
#   self.manuscript_abbrev = stencil.ms
#   self.citation_json     = citation.to_json
# end
#
