require "json"

# From the traject docs:
# #  A Reader is any class that:
#   1) Has a two-argument initializer taking an IO stream and a Settings hash
#   2) Responds to the usual ruby #each, returning a source record from each #each.
#      (Including Enumerable is prob a good idea too)
#
# We don't need an IO stream, but we'll just ignore it
#
# Reader settings are
#   'med.bib_file' => the data file (bib_all.xml)

require "middle_english_dictionary"
require_relative "../../../lib/annoying_utilities"

module MedInstaller
  # Traject readers need to take an io object (which we don't need) and the
  # settings hash
  module Traject
    class BibReader
      def self.new(_io_we_ignore, settings)
        MedInstaller::BibReader.new(settings)
      end
    end
  end

  MED = MiddleEnglishDictionary

  class BibReader
    include Enumerable
    include MedInstaller::Logger

    DATAFILEKEY = "med.data_file"

    def initialize(settings)
      @data_file = get_data_file(settings)
    end

    def each
      MED::Collection::BibSet.new(filename: @data_file).each { |b| yield b }
    rescue => e
      require "pry"
      binding.pry # standard:disable Lint/Debugger
    end

    def get_data_file(settings)
      if settings.has_key?(DATAFILEKEY)
        Pathname.new(settings[DATAFILEKEY])
      else
        raise "Need to specify filename in #{DATAFILEKEY} for #{self.class}"
      end
    end
  end
end
