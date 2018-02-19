require 'middle_english_dictionary'
require_relative '../lib/annoying_utilities'
require_relative '../lib/med_installer'

settings do
  provide "log.batch_progress", 5_000
  provide 'med.data_dir', Pathname(__dir__).parent.parent + 'data'
  provide 'med.letters', '[A-Z]'
  provide 'med.letters', 'A'
  provide "reader_class_name", 'MedInstaller::Traject::EntryJsonReader'
end


# # Create a hash that can be sent to solr
# def solr_doc
#   doc        = {}
#   doc[:id]   = id
#   doc[:type] = 'entry'
#   doc[:sequence] = seq
#
#   doc[:keywords] = Nokogiri::XML(xml).text # should probably just copyfield all the important stuff
#   doc[:json] = self.to_h.to_json
#
#   if form and form.pos
#     doc[:pos_abbrev] = form.normalized_pos
#     doc[:pos]        = form.pos
#   end
#
#   doc[:usage] = usages
#
#   doc[:official_headword] = headword.orig
#   doc[:headword]      = headword.regs
#
#   doc[:orth] = (form.orths.flat_map(&:orig) + form.orths.flat_map(&:regs)).flatten.uniq.reject{|x| x =~ /\)/}
#
#   if senses and senses.size > 0
#     doc[:definition_xml]  = senses.map(&:definition_xml)
#     doc[:definition_text] = senses.map(&:definition_text)
#   end
#
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

to_field 'type' do |rec, acc|
  acc << 'entry'
end

# Raw forms
to_field 'xml', entry_field(:xml)
to_field 'json', entry_field(:json)


# headwords and forms
to_field('headword') do |rec, acc|
  rec.headwords.each do |h|
    acc << h.orig
  end
end



