require 'middle_english_dictionary'
require_relative '../lib/annoying_utilities'
require_relative '../lib/med_installer'

settings do
  provide "log.batch_progress", 5_000
  provide 'med.data_dir', Pathname(__dir__).parent.parent + 'data'
  # provide 'med.letters', '[A-Z]'
  provide 'med.letters', 'A'
  provide "reader_class_name", 'MedInstaller::Traject::EntryJsonReader'
end


# # Create a hash that can be sent to solr
# def solr_doc
#    doc[:keywords] = Nokogiri::XML(xml).text # should probably just copyfield all the important stuff

#   if form and form.pos
#     doc[:pos_abbrev] = form.normalized_pos
#     doc[:pos]        = form.pos
#   end

#   doc[:etyma_language] = @etyma_languages
#
#   doc[:quote] = quotes.map(&:text)
#   doc
# end

def entry_field(name)
  ->(rec, acc) {acc << rec.send(name)}
end


# What do we have?
to_field 'id', entry_field(:id)

to_field 'type' do |entry, acc|
  acc << 'entry'
end

to_field 'sequence', entry_field(:sequence)

# Raw forms
# to_field 'xml', entry_field(:xml)
# to_field 'json', entry_field(:json)


# headwords and forms
to_field 'official_headword', entry_field(:original_headwords)
to_field 'headword', entry_field(:regularized_headwords)
to_field 'orth', entry_field(:all_forms)

# Definitions and modern equivalents
to_field('definition_text') do |entry, acc|
  acc.replace entry.senses.flat_map(&:definition_text)
end

to_field('oed_norm') do |entry, acc|
  acc << entry.oedlink.norm
end

# Usages
#      * create tmaps
to_field('discipline_usage') do |entry, acc|
  acc.replace entry.senses.flat_map(&:discipline_usages).compact.uniq
end

to_field('grammatical_usage') do |entry, acc|
  acc.replace entry.senses.flat_map(&:grammatical_usages).compact.uniq
end

# Etymology and pos
to_field 'etyma_language', entry_field(:etym_languages)
to_field 'pos_raw', entry_field(:pos_raw)
to_field 'pos_abbrev', entry_field(:normalized_pos_raw)

# Quotes
to_field('quote_text') do |entry, acc|
  acc.replace entry.all_quotes.map(&:text)
end
to_field('quote_md') do |entry, acc|
  acc.replace entry.all_citations.flat_map(&:md).uniq.compact
end
to_field('quote_cd') do |entry, acc|
  acc.replace entry.all_citations.flat_map(&:cd).uniq.compact
end
to_field('quote_title') do |entry, accc|
  acc.replace entry.all_citations.flat_map(&:bibs).flat_map(&:stencil).flat_map(&:title)
end
to_field('quote_manuscript') do |entry, accc|
  acc.replace entry.all_citations.flat_map(&:bibs).flat_map(&:stencil).flat_map(&:ms)
end
to_field('quote_rid') do |entry, accc|
  acc.replace entry.all_citations.flat_map(&:bibs).flat_map(&:stencil).flat_map(&:rid)
end



