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

    DATADIRKEY = 'med.data_dir'
    LETTERSKEY = 'med.letters'

    def self.new(settings)
      @data_dir   = get_data_dir(settings)
      @letters    = get_letters(settings)
      target_dirs = AnnoyingUtilities.target_directories(@data_dir, 'json', @letters)
      entries     = MiddleEnglishDictionary::Collection::EntrySet.new
      target_dirs.each do |dir|
        entries.load_dir_of_json_files(dir)
      end
      entries
    end


    def self.get_letters(settings)
      if settings.has_key?(LETTERSKEY)
        settings[LETTERSKEY]
      else
        '[A-Z]'
      end
    end

    def self.get_data_dir(settings)
      if settings.has_key?(DATADIRKEY)
        settings[DATADIRKEY]
      else
        raise "Need to specify #{DATADIRKEY} in settings for #{self.class}"
      end
    end
  end

end

