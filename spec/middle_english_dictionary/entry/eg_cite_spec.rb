require_relative "../spec_helper"
require "middle_english_dictionary/entry"

RSpec.describe MiddleEnglishDictionary::Entry::EG do
  let(:e) { MiddleEnglishDictionary::Entry.new_from_xml_file(SPEC_DATA + "well_rounded.xml") }

  it "gets the right subdef letters" do
    expect(e.senses.first.egs.map(&:subdef_entry)).to match_array(%w[a b])
  end

  it "Gets empty string when there is no subdef letter" do
    expect(e.senses[1].egs.first.subdef_entry).to eq("")
  end

  it "gets the right number of citations" do
    expect(e.senses.first.egs.first.citations.count).to be(9)
    expect(e.senses.first.egs[1].citations.count).to be(1)
    expect(e.senses[1].egs.first.citations.count).to be(2)
  end

  it "extracts data from the stencils" do
    stencils = e.senses[1].egs.first.citations.flat_map { |x| x.bib.stencil }
    expect(stencils.map(&:rid)).to match_array(%w[hyp.148.20011127T144602 hyp.100.19991101T123123])
  end

  it "gets all the quotes" do
    expect(e.all_quotes.count).to be(14)
  end
end
