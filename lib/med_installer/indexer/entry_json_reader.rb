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

  # Traject reader adapter that yields parsed {MiddleEnglishDictionary::Entry} objects
  # from +entries.json.gz+ (newline-delimited JSON, gzip-compressed).
  #
  # The IO argument required by the Traject reader contract is ignored; the real
  # data path comes from +Services[:entries_gz_file]+.
  class EntryJsonReader
    include Enumerable
    include MedInstaller::Logger

    # @param settings [Hash] Traject settings hash (IO argument is ignored)
    def initialize(settings)
      @data_file = Dromedary::Services[:entries_gz_file]
    end

    # Removes all pipe (+|+) characters from a JSON string.
    # Pipes are invalid in the MED data and cause JSON parse errors if present.
    # @param j [String] raw JSON line
    # @return [String] JSON with pipes removed
    def depipe_json(j)
      j.delete("|")
    end

    # Yields each parsed entry from the gzip-compressed NDJSON file.
    # Skips blank lines and logs (then re-raises) any parse errors.
    # @yield [MiddleEnglishDictionary::Entry] each parsed entry
    # @return [void]
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
