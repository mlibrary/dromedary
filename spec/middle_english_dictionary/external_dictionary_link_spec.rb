require_relative "spec_helper"
require "middle_english_dictionary/collection/external_dictionary_link_set"

RSpec.describe MiddleEnglishDictionary::Collection::OEDLinkSet do
  let(:links) { described_class.from_xml_file(SPEC_DATA + "oed_links.xml") }

  it "parses normalized terms and target data" do
    b_link = links["MED3363"]
    expect(b_link.normalized_term).to eq("B")
    expect(b_link.targets.map(&:target_id)).to eq(["14168"])
    expect(b_link.targets.map(&:term)).to eq(["B, n."])

    expect(links["MED3364"].normalized_term).to eq("ba")
    expect(links["MED3366"].normalized_term).to eq("babanly")
  end

  it "omits links with placeholder target ids" do
    expect(links["MED3365"]).to be_nil
  end
end
