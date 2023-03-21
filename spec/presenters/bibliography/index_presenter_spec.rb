require "rails_helper"

require_relative "../../../app/presenters/bibliography/index_presenter"

class MockView < ActionView::Base
  def search_state
  end
end

RSpec.describe Dromedary::Bib::IndexPresenter, pending: "review" do
  let(:presenter) { described_class.new(document, view_context, configuration) }
  let(:document) { instance_double(SolrDocument, "document") }
  let(:view_context) { instance_double(MockView, "view_context", search_state: search_state) }
  let(:search_state) { instance_double(Blacklight::SearchState, "search_state", params_for_search: params_for_search) }
  let(:params_for_search) { {} }
  let(:configuration) { double("configuration") }
  let(:blacklight_config) { instance_double(Blacklight::Configuration, "blacklight_config") }
  let(:bibliography_json) { "{}" }
  let(:bibliography) { instance_double(MiddleEnglishDictionary::Bib, "bibliography", xml: bibliography_xml, incipit?: incipit) }
  let(:bibliography_xml) { "" }
  let(:incipit) { double("incipit") }
  let(:nokonode) { instance_double(Nokogiri::XML::Node, "nokonode") }

  before do
    allow(Blacklight::IndexPresenter).to receive(:new).with(document, view_context, configuration).and_call_original
    allow(document).to receive(:fetch).with("json").and_return(bibliography_json)
    allow(MiddleEnglishDictionary::Bib).to receive(:from_json).with(bibliography_json).and_return(bibliography)
    allow(Nokogiri::XML::Document).to receive(:parse).and_call_original
    allow(Nokogiri::XML::Document).to receive(:parse).with(bibliography_xml, nil, nil, Nokogiri::XML::ParseOptions::DEFAULT_XML).and_return(nokonode)
    allow(nokonode).to receive(:css).with("VARGROUP").and_return([])
  end

  describe "#variants?" do
    it { expect(presenter.variants?).to be true }
  end

  describe "#incipit?" do
    it { expect(presenter.incipit?).to be false }
  end

  describe "#common_xsl" do
    it { expect(presenter.common_xsl).to eq "" }
  end

  describe "#msgroup_xsl" do
    it { expect(presenter.msgroup_xsl).to eq "" }
  end

  describe "#vargroup_xsl" do
    it { expect(presenter.vargroup_xsl).to eq "" }
  end

  describe "#commonify" do
    let(:xml) { nil }

    it { expect(presenter.commonify(xml)).to eq "review" }
    it { expect(presenter.commonify(Nokogiri::XML(xml))).to eq "review" }
  end

  describe "#title_html" do
    it { expect(presenter.title_html).to eq "" }
  end

  describe "#ms_title_html" do
    let(:ms) { nil }

    it { expect(presenter.ms_title_html(ms)).to eq "" }
  end

  describe "#ms_laeme_html" do
    let(:ms) { nil }

    it { expect(presenter.ms_laeme_html(ms)).to eq "" }
  end

  describe "#e_editions_title_link_pairs" do
    it { expect(presenter.e_editions_title_link_pairs).to eq "" }
  end

  describe "#external_reference_kvpairs" do
    it { expect(presenter.external_reference_kvpairs).to eq "" }
  end

  describe "#editions_xmls" do
    it { expect(presenter.editions_xmls).to eq "" }
  end

  describe "#msgroups_xmls" do
    it { expect(presenter.msgroup_xsl).to eq "" }
  end

  describe "#num_stencils" do
    it { expect(presenter.num_stencils).to eq 0 }
  end

  describe "#num_manuscripts" do
    it { expect(presenter.num_manuscripts).to eq 0 }
  end

  describe "#first_work" do
    it { expect(presenter.first_work).to eq "" }
  end
end
