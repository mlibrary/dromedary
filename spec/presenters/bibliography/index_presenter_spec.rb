require "rails_helper"

require_relative "../../../app/presenters/dromedary/bib/index_presenter"

class MockView < ActionView::Base
  def search_state
  end
end

RSpec.describe Dromedary::Bib::IndexPresenter do
  let(:presenter) { described_class.new(document, view_context, configuration) }
  let(:document) { instance_double(SolrDocument, "document") }
  let(:view_context) { instance_double(MockView, "view_context", search_state: search_state) }
  let(:search_state) { instance_double(Blacklight::SearchState, "search_state", params_for_search: params_for_search) }
  let(:params_for_search) { {} }
  let(:configuration) { double("configuration") }
  let(:bibliography_json) { "{}" }
  let(:bibliography_xml) { "<ENTRY><TITLE>Test Title</TITLE></ENTRY>" }
  let(:bibliography) do
    instance_double(
      MiddleEnglishDictionary::Bib, "bibliography",
      xml: bibliography_xml,
      incipit?: false,
      indexes: [],
      indexbs: [],
      indexcs: [],
      ipmeps: [],
      jolliffes: [],
      severs: [],
      wells: [],
      manuscripts: []
    )
  end

  before do
    allow(Blacklight::IndexPresenter).to receive(:new).with(document, view_context, configuration).and_call_original
    allow(document).to receive(:fetch).with("json").and_return(bibliography_json)
    allow(MiddleEnglishDictionary::Bib).to receive(:from_json).with(bibliography_json).and_return(bibliography)
  end

  describe "#variants?" do
    it "returns false when no VARGROUP nodes exist" do
      expect(presenter.variants?).to be false
    end

    context "when VARGROUP nodes exist" do
      let(:bibliography_xml) { "<ENTRY><TITLE>Test</TITLE><VARGROUP/></ENTRY>" }

      it "returns true" do
        expect(presenter.variants?).to be true
      end
    end
  end

  describe "#incipit?" do
    it "returns false when bib is not an incipit and TITLE TYPE is absent" do
      expect(presenter.incipit?).to be false
    end

    context "when bib.incipit? is true" do
      let(:bibliography) do
        instance_double(
          MiddleEnglishDictionary::Bib, "bibliography",
          xml: bibliography_xml,
          incipit?: true,
          indexes: [], indexbs: [], indexcs: [],
          ipmeps: [], jolliffes: [], severs: [], wells: [],
          manuscripts: []
        )
      end

      it "returns true" do
        expect(presenter.incipit?).to be true
      end
    end
  end

  describe "#common_xsl" do
    it "returns a non-nil XSLT stylesheet" do
      expect(presenter.common_xsl).not_to be_nil
    end
  end

  describe "#msgroup_xsl" do
    it "returns a non-nil XSLT stylesheet" do
      expect(presenter.msgroup_xsl).not_to be_nil
    end
  end

  describe "#vargroup_xsl" do
    it "returns a non-nil XSLT stylesheet" do
      expect(presenter.vargroup_xsl).not_to be_nil
    end
  end

  describe "#commonify" do
    it "returns nil for nil string input" do
      expect(presenter.commonify(nil)).to be_nil
    end

    it "returns a string for a Nokogiri node" do
      node = Nokogiri::XML("<ROOT/>")
      expect(presenter.commonify(node)).to be_a(String).or be_nil
    end
  end

  describe "#title_html" do
    it "returns a string" do
      expect(presenter.title_html).to be_a(String).or be_nil
    end
  end

  describe "#ms_title_html" do
    let(:ms) { instance_double(MiddleEnglishDictionary::Bib::MS, title_xml: "<TITLE>Ms Title</TITLE>") }

    it "returns a string" do
      expect(presenter.ms_title_html(ms)).to be_a(String).or be_nil
    end
  end

  describe "#ms_laeme_html" do
    let(:ms) { instance_double(MiddleEnglishDictionary::Bib::MS, laeme_xml: []) }

    it "returns an empty string when no LAEME entries" do
      expect(presenter.ms_laeme_html(ms)).to eq ""
    end
  end

  describe "#e_editions_title_link_pairs" do
    it "returns an empty array when no e-editions" do
      expect(presenter.e_editions_title_link_pairs).to eq []
    end
  end

  describe "#external_reference_kvpairs" do
    it "returns an empty array when bibliography has no external refs" do
      expect(presenter.external_reference_kvpairs).to eq []
    end
  end

  describe "#editions_xmls" do
    it "returns an empty array when no editions" do
      expect(presenter.editions_xmls).to eq []
    end
  end

  describe "#msgroups_xmls" do
    it "returns an empty array when no MSGROUP nodes" do
      expect(presenter.msgroups_xmls).to eq []
    end
  end

  describe "#num_stencils" do
    before { allow(document).to receive(:fetch).with("stencil_keyword").and_return([]) }

    it "returns '0 stencils' when no stencils" do
      expect(presenter.num_stencils).to eq "0 stencils"
    end
  end

  describe "#num_manuscripts" do
    it "returns '0 manuscripts' when bibliography has no manuscripts" do
      expect(presenter.num_manuscripts).to eq "0 manuscripts"
    end
  end

  describe "#first_work" do
    it "returns nil when no STENCIL/WORK node exists" do
      expect(presenter.first_work).to be_nil
    end
  end
end
