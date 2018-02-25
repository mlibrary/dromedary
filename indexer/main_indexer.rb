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

def entry_method(name)
  ->(rec, acc) {acc << rec.send(name)}
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

# Definitions and modern equivalents
to_field('definition_text') do |entry, acc|
  acc.replace entry.senses.flat_map(&:definition_text)
end

to_field('oed_norm') do |entry, acc|
  acc << entry.oedlink.norm if entry.oedlink
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
to_field 'etyma_language', entry_method(:etym_languages)
to_field 'pos_raw', entry_method(:pos_raw)
to_field 'pos_abbrev', entry_method(:normalized_pos_raw)

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
to_field('quote_title') do |entry, acc|
  acc.replace entry.all_stencils.flat_map(&:title)
end
to_field('quote_manuscript') do |entry, acc|
  acc.replace entry.all_stencils.flat_map(&:ms)
end

each_record do |entry, context|
  context.clipboard[:rids] = entry.all_stencils.flat_map(&:rid)
end

to_field('quote_rid') do |entry, acc, context|
  acc.replace context.clipboard[:rids]
end



