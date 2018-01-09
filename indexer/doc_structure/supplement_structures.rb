$:.unshift '../lib'
require 'pathname'
require 'dromedary/entry'
require 'dromedary/entry_set'
datadir = Pathname(ARGV.shift)
letters = ARGV

letters = ('A'..'Z').to_a if letters.empty?


entries = Dromedary::EntrySet.new
entries.load_by_letter(datadir, *letters)

puts "Loaded #{entries.count} entries into 'entries' (a #{entries.class})"

docs_with_supplements = entries.lazy.map {|e| Nokogiri::XML(e.xml)}.select {|d| d.css('SUPPLEMENT').size > 0}

puts "Found #{docs_with_supplements.count} documents with supplements"

TAGS_I_CARE_ABOUT = %w[EG CIT BIBL NOTE Q EG SUPPLEMENT STCNL]
require 'set'
ALL_TAGS = Set.new
def supplement_paths(supp)
  return nil if supp.nil?
  # return [supp.name] unless supp.children.count > 0
  ALL_TAGS << supp.name
  downpaths = supp.children.select {|x| TAGS_I_CARE_ABOUT.include?(x.name)}.flat_map {|c| supplement_paths(c)}.compact
  return [supp.name] if downpaths.empty?
  downpaths.map {|x| [supp.name, x].join('/')}
end

paths = docs_with_supplements.flat_map{|x| x.css('SUPPLEMENT').flat_map{|y| supplement_paths(y)}}.to_a
upaths = paths.uniq

puts upaths.sort.join("\n")

#puts ALL_TAGS.to_a.join("\n")
