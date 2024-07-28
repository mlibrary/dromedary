require "json"
require "zlib"

# From the traject docs:
# #  A Reader is any class that:
#   1) Has a two-argument initializer taking an IO stream and a Settings hash
#   2) Responds to the usual ruby #each, returning a source record from each #each.
#      (Including Enumerable is prob a good idea too)
#
# We don't need an IO stream, but we'll one and just ignore it
#
# Reader settings are
#   'med.data_file' => the data file (entries.ndj)

require "middle_english_dictionary"
require "dromedary/services"

module MedInstaller
  # Traject readers need to take an io object (which we don't need) and the
  # settings hash
  module Traject
    class EntryJsonReader
      def self.new(_io_we_ignore, settings)
        MedInstaller::EntryJsonReader.new(settings)
      end
    end
  end

  class EntryJsonReader
    include Enumerable
    include MedInstaller::Logger

    def initialize(settings)
      @data_file = Dromedary::Services[:entries_gz_file]
    end

    # This is the dumbest thing ever, but we need to eliminate all pipes
    # from the input, and this easiest way to do it.
    #
    # Of course, it presupposes there aren't any *wanted* pipes
    # in the input, which for now we're just assuming.
    def depipe_json(j)
      j.delete("|")
    end

    def each
      Zlib::GzipReader.new(File.open(@data_file)).each_with_index do |json_line, index|
        next unless /\S/.match?(json_line)
        begin
          entry = MiddleEnglishDictionary::Entry.from_json(depipe_json(json_line))
          yield entry
        rescue => e
          logger.error "Error with json line #{index}: #{e}\n#{e.backtrace}"
          raise e
        end
      end
    end
  end
end
