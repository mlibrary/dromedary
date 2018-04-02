require 'middle_english_dictionary'

$LOAD_PATH.unshift Pathname.new(__dir__).parent + 'lib'
require 'annoying_utilities'
require 'med_installer'

settings do
  store "log.batch_size", 2_500
  provide 'med.data_dir', Pathname(__dir__).parent.parent + 'data'
  provide 'med.letters', '[A-Z]'
  # provide 'med.letters', 'A'
  provide "reader_class_name", 'MedInstaller::Traject::EntryJsonReader'
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

to_field "word_suggestions", entry_method(:all_forms)
to_field('headword_only_suggestions') do |entry, acc|
  hw = [entry.regularized_headwords, entry.original_headwords].flatten.uniq
  acc.replace hw
end

# Etymology and pos
to_field 'etyma_language', entry_method(:etym_languages)
to_field 'etyma_text', entry_method(:etym_text)

to_field 'pos_raw', entry_method(:pos_raw)
to_field 'pos_abbrev', entry_method(:normalized_pos_raw)

# Definitions and modern equivalents
to_field('definition_text') do |entry, acc|
  acc.replace entry.senses.flat_map(&:definition_text)
end

to_field('oed_norm') do |entry, acc|
  acc << entry.oedlink.norm if entry.oedlink
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

to_field('quote_md') do |entry, acc|
  acc.replace entry.all_citations.flat_map(&:md).uniq.compact
end
to_field('quote_cd') do |entry, acc|
  acc.replace entry.all_citations.flat_map(&:cd).uniq.compact
end


# Notes
to_field 'notes', entry_method(:notes)

# RIDs


each_record do |entry, context|
  context.clipboard[:rids] = entry.all_stencils.flat_map(&:rid).compact.uniq
end

to_field('quote_rid') do |entry, acc, context|
  acc.replace entry.all_stencils.flat_map(&:rid).compact.uniq
end


# Usages
#      * create tmaps
to_field('discipline_usage') do |entry, acc|
  acc.replace entry.senses.flat_map(&:discipline_usages).compact.uniq
end






