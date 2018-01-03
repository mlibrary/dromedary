$:.unshift 'lib'
require 'json'
require 'dromedary/entry'

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
jsondir = datadir + 'json'

dirs = ARGV.map(&:upcase)


alldirs     = Dir.new(jsondir).reject {|x| ['.', '..'].include? x}.map {|d| jsondir + d}.map(&:to_s).reject {|x| !File.directory?(x)}
target_dirs = if dirs.empty?
                alldirs
              else
                regexps = dirs.map {|x| Regexp.new("/#{x}*\\Z")}
                alldirs.select {|d| regexps.any? {|r| r.match(d)}}
              end


$stderr.puts "Loading json files into `entries`."

entries = Dromedary::EntrySet.new

target_dirs.each do |td|
  Dir.glob("#{td}/MED*.json") do |f|
    entries << Dromedary::Entry.from_h(JSON.parse(File.read(f), symbolize_names: true))
  end
end


require 'pry'; binding.pry

$stderr.puts "Goodbye"

