require 'pathname'
require 'middle_english_dictionary'

$:.unshift Pathname(__dir__).realdirpath.parent + "lib"

require 'json'


unless ARGV.size > 0
  puts "pry_session.rb; get a pry session with a bunch of entries loaded up"
  puts
  puts "Usage: ruby pry_session.rb /path/to/dir/with/json"
  puts
  exit(1)
end

datadir = Pathname(ARGV.shift)

entries = MiddleEnglishDictionary::Collection::EntrySet.new
entries.load_dir_of_json_files(datadir)

puts "Loaded #{entries.count} entries into 'entries' (a #{entries.class})"

require 'pry'; binding.pry

$stderr.puts "Goodbye"



