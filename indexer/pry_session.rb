require "pathname"
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile",
                                           Pathname.new(__FILE__).realpath)
require "rubygems"
require "bundler/setup"
$:.unshift Pathname(__dir__).realdirpath.parent + "lib"

require 'json'
require 'middle_english_dictionary'
require_relative '../lib/med_installer/indexer/entry_json_reader'


unless ARGV.size > 0
  puts "pry_session.rb; get a pry session with a bunch of entries loaded up"
  puts
  puts "Usage: ruby pry_session.rb /path/to/json/file"
  puts
  exit(1)
end



datafile = Pathname(ARGV.shift)
letters = ARGV.shift


settings = {
    'med.data_file' => datafile
}

entries = MedInstaller::EntryJsonReader.new(settings)
e = entries.first
require 'pry'; binding.pry

puts "Done"


