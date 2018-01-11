require 'pathname'

$:.unshift Pathname(__dir__).realdirpath.parent + "lib"

require 'json'


require 'dromedary/entry'
require 'dromedary/entry_set'

unless ARGV.size > 0
  puts "pry_session.rb; get a pry session with a bunch of entries loaded up"
  puts
  puts "Usage: ruby pry_session.rb /path/to/data [Optional Starting Letters]"
  puts
  puts "Example: all the words that start with A or C"
  puts "  ruby pry_session ../../data A C"
  puts
  exit(1)
end

datadir = Pathname(ARGV.shift)
letters = ARGV

entries = Dromedary::EntrySet.new
entries.load_by_letter(datadir, *letters)

puts "Loaded #{entries.count} entries into 'entries' (a #{entries.class})"

require 'pry'; binding.pry

$stderr.puts "Goodbye"



