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
require "dromedary/services"

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

  # Traject reader adapter that yields {MiddleEnglishDictionary::Collection::BibSet} entries.
  # Reads from +Services[:bib_all_xml_file]+.
  #
  # Traject readers must accept an IO object and a settings hash. The IO is
  # ignored here; the real data path comes from Services.
  class BibReader
    include Enumerable
    include MedInstaller::Logger

    DATAFILEKEY = "med.data_file"

    # @param settings [Hash] Traject settings hash (the IO argument is ignored)
    def initialize(settings)
      @data_file = Dromedary::Services[:bib_all_xml_file]
    end

    # Yields each bib entry from the XML file.
    # @yield [MiddleEnglishDictionary::Collection::Bib] each bib entry
    # @return [void]
    def each
      MED::Collection::BibSet.new(filename: @data_file).each { |b| yield b }
    rescue => e
      require "pry"
      binding.pry # standard:disable Lint/Debugger
    end

    # Resolves the data file path from the settings hash.
    # @param settings [Hash] must contain key +DATAFILEKEY+ (+med.data_file+)
    # @return [Pathname] the resolved data file path
    # @raise [RuntimeError] if the key is absent
    # @note This method is defined but never called internally (Settings are ignored
    #   in +initialize+); may be vestigial.
    def get_data_file(settings)
      if settings.has_key?(DATAFILEKEY)
        Pathname.new(settings[DATAFILEKEY])
      else
        raise "Need to specify filename in #{DATAFILEKEY} for #{self.class}"
      end
    end
  end
end
