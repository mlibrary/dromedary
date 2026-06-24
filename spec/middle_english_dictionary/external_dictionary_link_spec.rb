require_relative "spec_helper"
require "middle_english_dictionary/external_dictionary_link"
MEDO = MiddleEnglishDictionary::ExternalDictionaryLink

RSpec.describe MiddleEnglishDictionary::Entry do
  let(:links) { Nokogiri::XML(File.read(SPEC_DATA + "oed_links.xml")).xpath("/links/link") }

  it "constructs a link" do
    skip "Rework spec for new OED file format"

    link = MEDO.new_from_nokonode(links.first)
    expect(link.norm).to eq("B")
  end

  it "notices a lack of linking data" do
    # skip "Rework spec for new OED file format"

    link1 = MEDO.new_from_nokonode(links.first)
    link2 = MEDO.new_from_nokonode(links[2])
    expect(link1.linked?).to be(true)
    expect(link2.linked?).to be(false)
  end

  it "gets the norms" do
    # skip "Rework spec for new OED file format"

    norms = links.take(4).map { |x| MEDO.new_from_nokonode(x) }.map(&:norm)
    expect(norms).to match_array(%w[B ba baba babanly])
  end
end
