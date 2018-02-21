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
  ->(rec, acc) { acc << rec.send(name)}
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
to_field 'official_headword' , entry_field(:original_headwords)
to_field 'headword', entry_field(:regularized_headwords)
to_field 'orth', entry_field(:all_forms)

# Definitions
to_field('definition_text') do |entry, acc|
  acc.replace entry.senses.flat_map(&:definition_text)
end

# Usages
#      * create tmaps
to_field('discipline_usage') do |entry, acc|
  acc.replace entry.senses.flat_map(&:discipline_usages)
end

to_field('grammatical_usage') do |entry, acc|
  acc.replace entry.senses.flat_map(&:grammatical_usages)
end

to_field 'etyma_language', entry_field(:etym_languages)
to_field 'pos_raw', entry_field(:normalized_pos_raw)




