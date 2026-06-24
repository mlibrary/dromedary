require_relative "../spec_helper"
require "middle_english_dictionary/entry"

RSpec.describe MiddleEnglishDictionary::Entry do
  describe "With a basic document" do
    let(:e) { MiddleEnglishDictionary::Entry.new_from_xml_file(SPEC_DATA + "bare_bones.xml") }

    it "gets the original headword" do
      expect(e.original_headwords).to eq(%w[dē̆nūded])
    end

    it "gets the regularized headword" do
      expect(e.regularized_headwords).to eq(%w[denuded])
    end

    it "gets all headwords forms" do
      expect(e.all_headword_forms).to eq(%w[dē̆nūded denuded])
    end
  end

  describe "With a more complex document" do
    let(:e) { MiddleEnglishDictionary::Entry.new_from_xml_file(SPEC_DATA + "well_rounded.xml") }

    it "gets the original headwords" do
      expect(e.original_headwords).to eq(["brand-reth"])
    end

    it "gets the regularized headwords" do
      expect(e.regularized_headwords).to eq(%w[brand-reth brandreth])
    end

    it "gets all headword forms" do
      expect(e.all_headword_forms).to eq(%w[brand-reth brandreth])
    end

    it "gets all the original orth forms" do
      expect(e.original_orths).to eq %w[brand-rith -rath -ret -let -led brend-let brenled]
    end

    it "gets all the regularized forms" do
      expect(e.all_regularized_forms.size).to be(15)
    end

    it "#id" do
      expect(e.id).to eq("MED5829")
    end
    it "#sequence" do
      expect(e.sequence).to eq(5829)
    end

    it "gets the part of speech" do
      expect(e.pos).to eq("n.")
    end
    
    it "finds the etym languages" do
      expect(e.etym_languages).to eq(["Old Norse", "Old Icelandic", "Old English"])
    end

    it "gets all the senses" do
      expect(e.senses.count).to eq(2)
    end

    # more of a deep test
    it "gets all the citations" do
      expect(e.all_citations.count).to eq(14)
    end
  end
end
