require_relative "../spec_helper"
require "middle_english_dictionary/entry"

RSpec.describe MiddleEnglishDictionary::Entry do
  describe "Etymology" do
    let(:e) { MiddleEnglishDictionary::Entry.new_from_xml_file(SPEC_DATA + "well_rounded.xml") }
    let(:bb) { MiddleEnglishDictionary::Entry.new_from_xml_file(SPEC_DATA + "bare_bones.xml") }

    it "gets the etym xml" do
      expect(e.etym_xml).to match(%r{<LANG><LG.*?>OI</LG>})
    end

    it "gets the languages" do
      expect(e.etym_languages).to match_array(["Old Norse", "Old Icelandic", "Old English"])
    end

    it "returns nil when there is no etymology" do
      expect(bb.etym_xml).to be_nil
    end

    it "returns an empty list when there are no etym languages" do
      expect(bb.etym_languages).to eq([])
    end
  end
end
