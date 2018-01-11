$:.unshift 'lib'
require 'dromedary/entry'
require 'fileutils'

DATADIR = ARGV[0]

unless Dir.exist? DATADIR
  $stderr.puts <<~USAGE

    Usage: ruby marshal_everything.rb /path/to/data/dir/

    ...where the data dir is expected to have subdirs
         xml/A/MED...xml
         xml/B/MED...xml
         ...etc.

    Creates one marshaled entry for each XML file under 
    <datadir>/marshal/, and one marshal file with *all*
    the entries under <datadir>/all_entries.marshal
  USAGE
  exit(1)
end

datapath      = Pathname(DATADIR).realdirpath
marshal_files = Hash.new {|h, k| h[k] = []}
letter        = ''
Dir.glob("#{datapath}/xml/MED_[F-Z]*/MED*xml").each do |f|
  m           = %r(xml/((.*?)/(.*))\.xml\Z).match(f)
  this_letter = m[2]
  this_file   = m[1]
  if this_letter != letter
    $stderr.puts this_letter
    letter = this_letter
    mdir = (datapath + "marshal" + this_letter).to_s
    FileUtils.mkpath(mdir) unless File.exists? mdir
  end

  marshal_file_name = datapath + "marshal" + "#{this_file}.marshal"
  Marshal.dump(Dromedary::Entry.new(f), File.open(marshal_file_name, 'wb'))
  marshal_files[this_letter] << marshal_file_name
end

$stderr.puts "Beginning process of combining into all_entries.marshal"

entries = Dromedary::EntrySet.new
marshal_files.each_pair do |letter, filenames|
  $stderr.puts letter
  filenames.each do |f|
    begin
      entries << Marshal.load(File.open(f, 'rb'))
    rescue => err
      $stderr.puts "Problem with #{f}: #{err.message} / #{err.backtrace}"
    end
  end
end


puts "Got them all. Dumping all_entries.marshal"

Marshal.dump(entries, File.open(datapath + 'all_entries.marshal', 'wb'))


