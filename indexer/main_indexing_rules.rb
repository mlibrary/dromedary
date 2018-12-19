$LOAD_PATH.unshift Pathname.new(__dir__).to_s
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + 'lib').to_s
require 'annoying_utilities'
require 'med_installer'
require 'middle_english_dictionary'
require 'json'
require_relative '../config/load_local_config'

require 'quote/quote_indexer'
require 'serialization/indexable_quote'

settings do
  store 'log.batch_size', 2_500
  provide 'med.data_dir', Pathname(__dir__).parent.parent + 'data'
  provide 'reader_class_name', 'MedInstaller::Traject::EntryJsonReader'
  provide "solr_writer.batch_size", 250
end

hyp_to_bibid = Dromedary.hyp_to_bibid
bibset       = MiddleEnglishDictionary::Collection::BibSet.new(filename: settings['bibfile'])

# Do a terrible disservice to traject and monkeypatch it to take
# our existing logger

Traject::Indexer.send(:define_method, :logger, ->() {AnnoyingUtilities.logger})


def entry_method(name)
  ->(rec, acc) {acc.replace Array(rec.send(name))}
end

# Grab the nokonode to make life easier
each_record do |entry, context|
  context.clipboard[:nokonode] = Nokogiri::XML(entry.xml)
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
to_field 'keyword' do |entry, acc, context|
  acc << context.clipboard[:nokonode].text.gsub(/[\s\n]+/, ' ')
end


# headwords and forms
to_field 'headword', entry_method(:regularized_headwords)
to_field 'orth', entry_method(:all_regularized_forms)

# suffixes and prefixes
# So, we also want to prefer a suffix or prefix (start or ending
# with a dash) on a headword, so we'll send it up again with
# the dash escaped.

to_field 'prefix_suffix' do |entry, acc|
  entry.regularized_headwords.each do |hw|
    if hw =~ /\A\-/ or hw =~ /\-\Z/
      acc << hw
    end
  end
end

# Dubious entry?
each_record do |entry, context|
  context.clipboard[:dubious] = context.clipboard[:nokonode].at('/ENTRYFREE').attr('DUB') == 'Y'
end

to_field 'dubious' do |entry, acc, context|
  acc << 'Y' if context.clipboard[:dubious]
end

# We need to do the word sugggestions here (instead of in schema.xml
# with copyField) because copyField allows duplicates.

to_field 'word_suggestions', entry_method(:all_forms)
to_field('headword_only_suggestions') do |entry, acc|
  hw = entry.regularized_headwords
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

# Citations

to_field('citation_text') do |entry, acc|
  entry.all_citations.each do |c|
    acc << c.text
  end
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

to_field('min_md') do |entry, acc|
  acc << entry.all_citations.flat_map(&:md).compact.min
end

to_field('min_cd') do |entry, acc|
  acc << entry.all_citations.flat_map(&:cd).compact.min
end

# Author.Title
# We special-case this 'cause people want to search on, e.g.,
# Capgr.Chron. The '.' is *not* a breaking charactor for the
# me_text or text data types, so we can just use one

to_field 'authortitle' do |entry, acc|
  entry.all_stencils.each do |s|
    acc <<[s.author, s.title].compact.join('.').gsub(/\.+/, '.').gsub(/\.\Z/, '')
    acc << s.author
    acc << s.title
  end
  acc.uniq!

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
    next if q.text == ''
    if q.rid
      begin
        rid      = q.rid.gsub('\\', '').upcase # TODO: Take out when backslashes removed from HYP ids
        bid = hyp_to_bibid[rid]
        if bid
          q.bib_id = bid
          q.author = bibset[q.bib_id].author
        else
          logger.warn "RID #{rid} in #{entry.source} not found in bib_all.xml"
        end
      rescue => e
        require 'pry'; binding.pry
      end
    end

    q.headword = entry.headwords
    q.pos      = entry.pos
    q.dubious = 'Y' if context.clipboard[:dubious]
    q.entry = entry
    quote_indexer.put(q, context.position)
  end
end




