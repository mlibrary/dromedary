require "middle_english_dictionary/entry"
require "middle_english_dictionary/collection/hash_array"

module MiddleEnglishDictionary
  module Collection
    # A collection of {Entry} objects keyed by MED ID, loaded from a directory
    # of per-entry JSON files.
    #
    # Extends {HashArray} with bulk-loading and cross-reference attachment
    # methods so that a full set of MED entries can be assembled and enriched
    # in a few method calls.
    #
    # @example
    #   entries = EntrySet.new
    #   entries.load_dir_of_json_files("/data/med/entries")
    #   entries.add_oeds_from_file("/data/med/oed_links.xml")
    #   entries["MED3366"].oedlinks  #=> ExternalDictionaryLink
    class EntrySet < HashArray
      # Load all +MED*.json+ files from +rawdir+ and store each deserialized
      # {Entry} keyed by its {Entry#id}.
      #
      # Files whose names do not match the pattern +MED*.json+ are silently
      # skipped.
      #
      # @param rawdir [String, Pathname] path to the directory containing JSON
      #   entry files
      # @return [void]
      def load_dir_of_json_files(rawdir)
        dir = Pathname(rawdir)
        dir.children.select { |x| x.to_s =~ /MED.*\.json\Z/ }.each do |f|
          entry = MiddleEnglishDictionary::Entry.from_json_file(f)
          self[entry.id] = entry
        end
      end

      # Parse an OED cross-reference XML file and attach each
      # {ExternalDictionaryLink} to the matching entry.
      #
      # @param filename [String] path to the OED links XML file
      # @return [void]
      def add_oeds_from_file(filename)
        oeds = MiddleEnglishDictionary::Collection::OEDLinkSet.from_xml_file(filename)
        oeds.each_pair { |med_id, links| self[med_id].oed_links = links }
      end

      # Parse a DOE cross-reference XML file and attach each
      # {ExternalDictionaryLink} to the matching entry.
      #
      # @param filename [String] path to the DOE links XML file
      # @return [void]
      def add_does_from_file(filename)
        does = MiddleEnglishDictionary::Collection::OEDLinkSet.from_xml_file(filename)
        does.each_pair { |med_id, links| self[med_id].doe_links = links }
      end
    end
  end
end
