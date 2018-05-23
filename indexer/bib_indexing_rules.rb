$LOAD_PATH.unshift Pathname.new(__dir__).to_s
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + 'lib').to_s
require 'annoying_utilities'
require 'med_installer'
require 'middle_english_dictionary'

settings do
  provide 'log.batch_size', 2_500
  provide 'med.data_dir', Pathname(__dir__).parent.parent + 'data'
  provide 'reader_class_name', 'MedInstaller::Traject::BibReader'
end


# Do a terrible disservice to traject and monkeypatch it to take
# our existing logger

Traject::Indexer.send(:define_method, :logger, ->() {AnnoyingUtilities.logger})


def bib_method(name)
  ->(rec, acc) {acc.replace Array(rec.send(name))}
end

# Grab the nokonode to make life easier
each_record do |bib, context|
  context.clipboard[:nokonode] = Nokogiri::XML(bib.xml)
end

# What do we have and what do we call it?
to_field 'id', bib_method(:id)
to_field 'type' do |entry, acc|
  acc << 'bib'
end
to_field 'format' do |entry, acc|
  acc << 'bib'
end

# Raw form
to_field 'json', bib_method(:to_json)


### Searches #####

# Everything

to_field 'keyword' do |bib, acc, context|
  acc << context.clipboard[:nokonode].text.gsub(/[\s\n]+/, ' ')
end

# Author and Title

to_field 'author', bib_method(:author)
to_field 'title', bib_method(:title_text)
to_field 'author_sort', bib_method(:author_sort)


# External references

to_field 'index',  bib_method(:indexes)
to_field 'indexb', bib_method(:indexbs)
to_field 'indexc', bib_method(:indexcs)
to_field 'ipmep', bib_method(:ipmeps)
to_field 'jolliffe', bib_method(:jolliffes)
to_field 'severs', bib_method(:severs)
to_field 'wells', bib_method(:wells)

# LALME
to_field 'lalme' do |bib, acc|
  acc.replace bib.manuscripts.flat_map(&:lalme).flatten.uniq
end

to_field 'lalme_expansion' do |bib, acc|
  acc.replace bib.manuscripts.flat_map(&:lalme_regions).flatten.uniq
end


# Manuscripts

to_field 'manuscript_title' do |bib, acc|
  acc.replace bib.manuscripts.map(&:title).uniq
end

to_field 'manuscript_keyword' do |bib, acc, context|
  context.clipboard[:nokonode].xpath('MSLIST/MS').each do |ms|
    acc << ms.text
  end
end

