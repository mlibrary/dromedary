# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogController, type: :controller do
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:repository) { instance_double(Blacklight::Solr::Repository) }
  let(:connection) { instance_double(RSolr::Client) }
  let(:search_service) { instance_double(Blacklight::SearchService, repository: repository) }
  let(:autocomplete_config) do
    {
      "h" => {
        "solr_endpoint" => "headword_only_suggester",
        "search_component_name" => "headword_only_suggester"
      }
    }
  end

  before do
    blacklight_config.autocomplete = autocomplete_config
    allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
    allow(controller).to receive(:search_service).and_return(search_service)
    allow(repository).to receive(:connection).and_return(connection)
  end

  # Build a Solr suggest response in the structure that
  # Blacklight::Suggest::Response expects:
  #   { "suggest" => { endpoint => { query => { "suggestions" => [...] } } } }
  def suggest_response(endpoint, query, suggestions)
    { "suggest" => { endpoint => { query => { "suggestions" => suggestions } } } }
  end

  describe "GET #suggest" do
    context "with missing search_field param" do
      it "defaults to 'h'" do
        allow(connection).to receive(:send_and_receive).and_return(
          suggest_response("headword_only_suggester", "test", [])
        )

        get :suggest, params: { q: "test" }
        expect(response).to have_http_status(:success)
      end
    end

    context "with missing autocomplete config" do
      before { blacklight_config.autocomplete = {} }

      it "returns empty HTML" do
        get :suggest, params: { q: "test", search_field: "h" }
        expect(response.body).to eq("")
      end
    end

    context "with missing solr_endpoint in config" do
      before do
        blacklight_config.autocomplete = {
          "h" => { "search_component_name" => "headword_only_suggester" }
        }
      end

      it "returns empty HTML" do
        get :suggest, params: { q: "test", search_field: "h" }
        expect(response.body).to eq("")
      end
    end

    context "with missing search_component_name in config" do
      before do
        blacklight_config.autocomplete = {
          "h" => { "solr_endpoint" => "headword_only_suggester" }
        }
      end

      it "returns empty HTML" do
        get :suggest, params: { q: "test", search_field: "h" }
        expect(response.body).to eq("")
      end
    end

    context "when Solr returns suggestions" do
      let(:solr_response) do
        suggest_response("headword_only_suggester", "wor", [
          { "term" => "word1", "weight" => 10, "payload" => "" },
          { "term" => "word2", "weight" => 5, "payload" => "" }
        ])
      end

      before do
        allow(connection).to receive(:send_and_receive).and_return(solr_response)
      end

      it "returns HTML li elements" do
        get :suggest, params: { q: "wor", search_field: "h" }
        expect(response.body).to include("<li")
        expect(response.body).to include("word1")
        expect(response.body).to include("word2")
      end

      it "includes data-autocomplete-value attributes" do
        get :suggest, params: { q: "wor", search_field: "h" }
        expect(response.body).to include('data-autocomplete-value="word1"')
        expect(response.body).to include('data-autocomplete-value="word2"')
      end
    end

    context "when Solr raises an exception" do
      before do
        allow(connection).to receive(:send_and_receive).and_raise(Errno::ECONNREFUSED)
      end

      it "returns empty HTML (graceful degradation)" do
        get :suggest, params: { q: "test", search_field: "h" }
        expect(response.body).to eq("")
      end
    end

    context "with base_url param" do
      let(:solr_response) do
        suggest_response("headword_only_suggester", "hel", [
          { "term" => "hello", "weight" => 10, "payload" => "" }
        ])
      end
      let(:search_response) do
        {
          "response" => {
            "docs" => [
              { "id" => "hello_id", "headword" => "hello" }
            ]
          }
        }
      end

      before do
        allow(connection).to receive(:send_and_receive).with(
          "headword_only_suggester", anything
        ).and_return(solr_response)
        allow(connection).to receive(:send_and_receive).with(
          "search", anything
        ).and_return(search_response)
      end

      it "includes data-url attributes with document links" do
        get :suggest, params: { q: "hel", search_field: "h", base_url: "http://example.com/dict" }
        expect(response.body).to include('data-url="http://example.com/dict/hello_id"')
        expect(response.body).to include('<a href="http://example.com/dict/hello_id"')
      end
    end

    context "without base_url param" do
      let(:solr_response) do
        suggest_response("headword_only_suggester", "hel", [
          { "term" => "hello", "weight" => 10, "payload" => "" }
        ])
      end

      before do
        allow(connection).to receive(:send_and_receive).and_return(solr_response)
      end

      it "returns li elements without links" do
        get :suggest, params: { q: "hel", search_field: "h" }
        expect(response.body).to include("hello")
        expect(response.body).not_to include("data-url")
        expect(response.body).not_to include("<a href=")
      end
    end

    context "with suggestion term containing special HTML characters" do
      let(:solr_response) do
        suggest_response("headword_only_suggester", "<", [
          { "term" => "<script>alert('xss')</script>", "weight" => 10, "payload" => "" }
        ])
      end

      before do
        allow(connection).to receive(:send_and_receive).and_return(solr_response)
      end

      it "HTML-escapes the term to prevent XSS" do
        get :suggest, params: { q: "<", search_field: "h" }
        expect(response.body).not_to include("<script>")
        expect(response.body).to include("&lt;script&gt;")
      end
    end

    context "when batch-querying for document IDs" do
      let(:solr_response) do
        suggest_response("headword_only_suggester", "word",
          (1..15).map { |i| { "term" => "word#{i}", "weight" => i, "payload" => "" } }
        )
      end

      let(:search_response) do
        {
          "response" => {
            "docs" => (1..15).map { |i| { "id" => "id#{i}", "headword" => "word#{i}" } }
          }
        }
      end

      before do
        allow(connection).to receive(:send_and_receive).with(
          "headword_only_suggester", anything
        ).and_return(solr_response)
        allow(connection).to receive(:send_and_receive).with(
          "search", anything
        ).and_return(search_response)
      end

      it "batches document lookups in groups of 10" do
        get :suggest, params: { q: "word", search_field: "h", base_url: "http://example.com" }
        expect(connection).to have_received(:send_and_receive).with(
          "search", anything
        ).at_least(:once)
      end
    end

    context "with symbol-keyed config" do
      before do
        blacklight_config.autocomplete = {
          "h" => {
            solr_endpoint: "headword_only_suggester",
            search_component_name: "headword_only_suggester"
          }
        }
      end

      let(:solr_response) do
        suggest_response("headword_only_suggester", "wor", [
          { "term" => "word", "weight" => 10, "payload" => "" }
        ])
      end

      before do
        allow(connection).to receive(:send_and_receive).and_return(solr_response)
      end

      it "handles symbol-keyed config" do
        get :suggest, params: { q: "wor", search_field: "h" }
        expect(response.body).to include("word")
      end
    end
  end
end
