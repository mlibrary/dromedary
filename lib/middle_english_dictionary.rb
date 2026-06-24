# The +middle_english_dictionary+ gem provides Ruby models for the raw XML
# source data of the **Middle English Dictionary** (MED), a historical
# lexicon of the English language from approximately 1100 to 1500 CE.
#
# == Overview
#
# The MED is distributed as a large XML dataset containing two main
# components:
#
# * **Entry files** -- one XML file per dictionary entry, each rooted at
#   +<MED><ENTRYFREE>+, holding headword spellings, part-of-speech,
#   etymology, senses with definitions and example quotations, and
#   cross-references to the Oxford English Dictionary and the Dictionary
#   of Old English.
#
# * **Hyperbib file** -- a single +HYPERMED+ XML file containing the master
#   bibliography (+ENTRY+ records) and a manuscript library (+MSLIB/MSFULL+
#   records) that entries cite via +RID+ stencil cross-references.
#
# This gem provides:
#
# * {Entry} -- the central model, parsed from a single MED entry XML file
# * {Bib} -- a hyperbib bibliographic record
# * {ExternalDictionaryLink} -- an OED or DOE cross-reference
# * {Collection::EntrySet} -- a directory of JSON entry files as a keyed collection
# * {Collection::BibSet} -- the full hyperbib as a keyed collection
# * {Collection::OEDLinkSet} / {Collection::DOELinkSet} -- cross-reference collections
#
# == Typical usage
#
#   require "middle_english_dictionary"
#
#   # Parse a single entry from XML
#   entry = MiddleEnglishDictionary::Entry.new_from_xml_file("MED003366.xml")
#   entry.headwords.map(&:origs)   #=> [["don", "doon"], ...]
#
#   # Load a full set of pre-serialized JSON entries
#   entries = MiddleEnglishDictionary::Collection::EntrySet.new
#   entries.load_dir_of_json_files("/data/med/entries")
#   entries.add_oeds_from_file("/data/med/oed_links.xml")
#
#   # Load the hyperbib
#   bibs = MiddleEnglishDictionary::Collection::BibSet.new(filename: "hypermed.xml")
#   bibs["SOME-ID"].title_text
#
# @see Entry
# @see Bib
# @see Collection::EntrySet
# @see Collection::BibSet
require "middle_english_dictionary/version"
require "middle_english_dictionary/utilities"
require "middle_english_dictionary/entry"
require "middle_english_dictionary/collection/external_dictionary_link_set"
require "middle_english_dictionary/collection/entry_set"
require "middle_english_dictionary/collection/bib_set"
