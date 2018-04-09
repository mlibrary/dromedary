require 'json'

# From the traject docs:
# #  A Reader is any class that:
#   1) Has a two-argument initializer taking an IO stream and a Settings hash
#   2) Responds to the usual ruby #each, returning a source record from each #each.
#      (Including Enumerable is prob a good idea too)
#
# We don't need an IO stream, but we'll just ignore it
#
# Reader settings are
#   'med.data_dir' => the data directory
#   'med.letters' => (optional) array of letters that the entries start with [A-Z]
#                    Default is to index everything.
#


require 'middle_english_dictionary'
require_relative '../../../lib/annoying_utilities'

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

    DATADIRKEY  = 'med.data_dir'
    DATAFILEKEY = 'med.data_file'
    LETTERSKEY  = 'med.letters'

    def initialize(settings)
      @data_file = get_data_file(settings)
      @letters   = get_letters(settings)
    end

    def each
      if @letters
        letter_match = Regexp.new "\\A[#{@letters.join('')}]"
        last_letter  = @letters.map(&:downcase).sort.last
      end

      File.open(@data_file).each do |json_line|
        json_hash = JSON.parse(json_line)
        if @letters
          next unless json_hash['headwords'].any? {|x| letter_match.match(x)}
          last if json_hash['headword'].first[0] > last_letter
        end
        yield MiddleEnglishDictionary::Entry.from_json(json_line)
      end
    end

    def get_letters(settings)
      if settings.has_key?(LETTERSKEY)
        settings[LETTERSKEY]
      else
        nil
      end
    end

    def get_data_file(settings)
      if settings.has_key?(DATAFILEKEY)
        Pathname.new(settings[DATAFILEKEY])
      elsif settings.has_key[DATADIRKEY]
        Pathname.new(settings[DATADIRKEY]) + 'entrires.json'
      else
        raise "Need to specify filename in #{DATAFILEKEY} or directory that holds 'entries.json' in #{DATADIRKEY} in settings for #{self.class}"
      end
    end
  end

end

