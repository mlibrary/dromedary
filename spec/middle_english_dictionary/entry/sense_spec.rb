require_relative "../spec_helper"
require "middle_english_dictionary/entry/sense"

RSpec.describe MiddleEnglishDictionary::Entry::Sense do
  let(:sense_nokonode) { Nokogiri::XML(File.read(SPEC_DATA + "simple_sense.xml")).at("SENSE") }
  let(:sense) { MiddleEnglishDictionary::Entry::Sense.new_from_nokonode(sense_nokonode) }
  let(:bb) { MiddleEnglishDictionary::Entry.new_from_xml_file(SPEC_DATA + "bare_bones.xml") }

  it "Gets the sense number" do
    expect(sense.sense_number).to eq("1")
  end

  it "Uses '1' as a default when there is no sense number" do
    expect(bb.senses.first.sense_number).to eq("1")
  end

  it "Gets the usages" do
    expect(sense.discipline_usages).to eq(["Law"])
  end
end
