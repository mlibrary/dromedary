

$LOAD_PATH.unshift Pathname.new(__dir__).to_s
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + 'lib').to_s
require 'annoying_utilities'
require 'med_installer'
require 'middle_english_dictionary'

require 'quote/quote_indexer'
require 'serialization/indexable_quote'

settings do
  store 'log.batch_size', 2_500
  provide 'med.data_dir', Pathname(__dir__).parent.parent + 'data'
  provide 'reader_class_name', 'MedInstaller::Traject::EntryJsonReader'
end


# Do a terrible disservice to traject and monkeypatch it to take
# our existing logger

Traject::Indexer.send(:define_method, :logger, ->() {AnnoyingUtilities.logger })


def entry_method(name)
  ->(rec, acc) {acc.replace Array(rec.send(name))}
end


# What do we have?
to_field 'id', entry_method(:id)

to_field 'type' do |entry, acc|
  acc << 'entry'
end

to_field 'sequence', entry_method(:sequence)

# Raw forms
to_field 'xml', entry_method(:xml)
to_field 'json', entry_method(:to_json)
to_field 'keyword' do |entry, acc|
  acc << Nokogiri::XML(entry.xml).text.gsub(/[\s\n]+/, ' ')
end


# headwords and forms
to_field 'official_headword', entry_method(:original_headwords)
to_field 'headword', entry_method(:regularized_headwords)
to_field 'orth', entry_method(:all_forms)

# We need to do the word sugggestions here (instead of in schema.xml
# with copyField) because copyField allows duplicates.

to_field 'word_suggestions', entry_method(:all_forms)
to_field('headword_only_suggestions') do |entry, acc|
  hw = [entry.regularized_headwords, entry.original_headwords].flatten.uniq
  acc.replace hw
end

# Etymology and pos
to_field 'etyma_language', entry_method(:etym_languages)
to_field 'etyma_text', entry_method(:etym_text)

to_field 'pos', entry_method(:pos_facet)

# Definitions and modern equivalents
to_field('definition_text') do |entry, acc|
  acc.replace entry.senses.flat_map(&:definition_text)
end

to_field('oed_norm') do |entry, acc|
  acc << entry.oedlinks.normalized_term if entry.oedlinks
end

to_field('doe_norm') do |entry, acc|
  acc << entry.doelinks.normalized_term if entry.doelinks
end

# Quotes
to_field('quote_text') do |entry, acc|
  acc.replace entry.all_quotes.map(&:text)
end

to_field('quote_title') do |entry, acc|
  acc.replace entry.all_stencils.flat_map(&:title)
end
to_field('quote_manuscript') do |entry, acc|
  acc.replace entry.all_stencils.flat_map(&:ms).compact.uniq
end

to_field('md') do |entry, acc|
  acc.replace entry.all_citations.flat_map(&:md).uniq.compact
end
to_field('cd') do |entry, acc|
  acc.replace entry.all_citations.flat_map(&:cd).uniq.compact
end


# Notes
to_field 'notes', entry_method(:notes)


# RIDs

to_field('rid') do |entry, acc, context|
  acc.replace entry.all_stencils.flat_map(&:rid).compact.uniq
end


# Usages
#      * create tmaps
to_field('discipline_usage') do |entry, acc|
  acc.replace entry.senses.flat_map(&:discipline_usages).compact.uniq
end
#
# # Index the quotes using a purpose-made indexer
quote_indexer = Dromedary::QuoteIndexer.new(settings)
each_record do |entry, context|
  entry.all_citations.each do |citation|
    q = Dromedary::IndexableQuote.new(citation: citation)
    quote_indexer.put(q, context.position)
  end
end




