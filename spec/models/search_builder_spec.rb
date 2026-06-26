# frozen_string_literal: true

# NOTE: SearchBuilder is intentionally unused — see app/models/search_builder.rb.
# These tests validate the processor methods in isolation for when a real
# query parser replaces the current default Blacklight::SearchBuilder.

require "rails_helper"

RSpec.describe SearchBuilder do
  let(:user_params) { {} }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:scope) { double blacklight_config: blacklight_config }
  subject(:search_builder) { described_class.new(scope).with(user_params) }

  describe "#yogh_to_ezh" do
    let(:solr_params) { { "q" => query } }

    context "with capital yogh (Ȝ)" do
      let(:query) { "Ȝword" }

      it "replaces with ezh (ʒ)" do
        search_builder.yogh_to_ezh(solr_params)
        expect(solr_params["q"]).to eq("ʒword")
      end
    end

    context "with lowercase yogh (ȝ)" do
      let(:query) { "worȝ" }

      it "replaces with ezh (ʒ)" do
        search_builder.yogh_to_ezh(solr_params)
        expect(solr_params["q"]).to eq("worʒ")
      end
    end

    context "with mixed yogh characters" do
      let(:query) { "Ȝeȝer" }

      it "replaces all occurrences" do
        search_builder.yogh_to_ezh(solr_params)
        expect(solr_params["q"]).to eq("ʒeʒer")
      end
    end

    context "with no yogh characters" do
      let(:query) { "normal query" }

      it "does not change the query" do
        search_builder.yogh_to_ezh(solr_params)
        expect(solr_params["q"]).to eq("normal query")
      end
    end

    context "with nil query" do
      let(:query) { nil }

      it "returns nil (nil-safe via &.)" do
        search_builder.yogh_to_ezh(solr_params)
        expect(solr_params["q"]).to be_nil
      end
    end

    context "with empty string query" do
      let(:query) { "" }

      it "does not change the empty string" do
        search_builder.yogh_to_ezh(solr_params)
        expect(solr_params["q"]).to eq("")
      end
    end
  end

  describe "#escape_intersticial_parens" do
    let(:solr_params) { { "q" => query } }

    context "with 2-letter paren group" do
      let(:query) { "foo(ar)bar" }

      it "escapes the parens" do
        search_builder.escape_intersticial_parens(solr_params)
        expect(solr_params["q"]).to eq("foo\\(ar\\)bar")
      end
    end

    context "with 1-letter paren group" do
      let(:query) { "foo(a)bar" }

      it "escapes the parens" do
        search_builder.escape_intersticial_parens(solr_params)
        expect(solr_params["q"]).to eq("foo\\(a\\)bar")
      end
    end

    context "with 3-letter paren group" do
      let(:query) { "foo(abc)bar" }

      it "escapes the parens" do
        search_builder.escape_intersticial_parens(solr_params)
        expect(solr_params["q"]).to eq("foo\\(abc\\)bar")
      end
    end

    context "with >3 letter paren group" do
      let(:query) { "foo(abcdefgh)bar" }

      it "does not change" do
        search_builder.escape_intersticial_parens(solr_params)
        expect(solr_params["q"]).to eq("foo(abcdefgh)bar")
      end
    end

    context "with numeric paren group" do
      let(:query) { "foo(123)bar" }

      it "does not change (non-alpha)" do
        search_builder.escape_intersticial_parens(solr_params)
        expect(solr_params["q"]).to eq("foo(123)bar")
      end
    end

    context "with mixed alpha-numeric paren group" do
      let(:query) { "foo(a1)bar" }

      it "does not change (contains digits)" do
        search_builder.escape_intersticial_parens(solr_params)
        expect(solr_params["q"]).to eq("foo(a1)bar")
      end
    end

    context "with Unicode letter paren group" do
      let(:query) { "foo(é)bar" }

      it "escapes the parens (Unicode alpha matched)" do
        search_builder.escape_intersticial_parens(solr_params)
        expect(solr_params["q"]).to eq("foo\\(é\\)bar")
      end
    end

    context "with preceding dash letter paren group" do
      let(:query) { "foo(-t)bar" }

      it "does not change (dash inside parens makes content non-alpha)" do
        search_builder.escape_intersticial_parens(solr_params)
        expect(solr_params["q"]).to eq("foo(-t)bar")
      end
    end

    context "with adjacent paren groups" do
      let(:query) { "foo(ab)bar(cd)baz" }

      it "escapes both paren groups" do
        search_builder.escape_intersticial_parens(solr_params)
        expect(solr_params["q"]).to eq("foo\\(ab\\)bar\\(cd\\)baz")
      end
    end

    context "with no parens" do
      let(:query) { "normal query" }

      it "does not change" do
        search_builder.escape_intersticial_parens(solr_params)
        expect(solr_params["q"]).to eq("normal query")
      end
    end

    context "with nil query" do
      let(:query) { nil }

      it "does not crash and leaves nil" do
        search_builder.escape_intersticial_parens(solr_params)
        expect(solr_params["q"]).to be_nil
      end
    end

    context "with empty string query" do
      let(:query) { "" }

      it "does not change" do
        search_builder.escape_intersticial_parens(solr_params)
        expect(solr_params["q"]).to eq("")
      end
    end
  end

  describe "#escape_prefix_suffix_dash" do
    let(:solr_params) { { "q" => query } }

    context "with dash after closing brace (MED prefix)" do
      let(:query) { "}-ward" }

      it "escapes the leading dash" do
        search_builder.escape_prefix_suffix_dash(solr_params)
        expect(solr_params["q"]).to eq("}\\-ward")
      end
    end

    context "with space-dash prefix" do
      let(:query) { "word -thing" }

      it "escapes the dash after space" do
        search_builder.escape_prefix_suffix_dash(solr_params)
        expect(solr_params["q"]).to eq("word \\-thing")
      end
    end

    context "with dash-space suffix" do
      let(:query) { "word- " }

      it "escapes the trailing dash" do
        search_builder.escape_prefix_suffix_dash(solr_params)
        expect(solr_params["q"]).to eq("word\\- ")
      end
    end

    context "with dash at end of string" do
      let(:query) { "something-" }

      it "escapes the trailing dash" do
        search_builder.escape_prefix_suffix_dash(solr_params)
        expect(solr_params["q"]).to eq("something\\-")
      end
    end

    context "with mid-word dash" do
      let(:query) { "no-dash" }

      it "does not change (mid-word dash unaffected)" do
        search_builder.escape_prefix_suffix_dash(solr_params)
        expect(solr_params["q"]).to eq("no-dash")
      end
    end

    context "with full Solr local params string" do
      let(:query) { "{!qf=$headword_and_forms_qf pf=$headword_and_forms_pf}-ward" }

      it "escapes the dash after braces but leaves local params intact" do
        search_builder.escape_prefix_suffix_dash(solr_params)
        expect(solr_params["q"]).to eq("{!qf=$headword_and_forms_qf pf=$headword_and_forms_pf}\\-ward")
      end
    end

    context "with multiple dash patterns" do
      let(:query) { "}-ward word -thing end- " }

      it "escapes all dashes" do
        search_builder.escape_prefix_suffix_dash(solr_params)
        expect(solr_params["q"]).to eq("}\\-ward word \\-thing end\\- ")
      end
    end

    context "with nil query" do
      let(:query) { nil }

      it "returns nil" do
        search_builder.escape_prefix_suffix_dash(solr_params)
        expect(solr_params["q"]).to be_nil
      end
    end

    context "with empty string" do
      let(:query) { "" }

      it "returns empty string" do
        search_builder.escape_prefix_suffix_dash(solr_params)
        expect(solr_params["q"]).to eq("")
      end
    end
  end

  describe "#default_to_everything_search" do
    let(:solr_params) { { "q" => query } }

    context "with nil query" do
      let(:query) { nil }

      it "sets q to *" do
        search_builder.default_to_everything_search(solr_params)
        expect(solr_params["q"]).to eq("*")
      end

      it "sets blacklight_params q to *" do
        search_builder.default_to_everything_search(solr_params)
        expect(search_builder.blacklight_params["q"]).to eq("*")
      end
    end

    context "with empty string query" do
      let(:query) { "" }

      it "sets q to *" do
        search_builder.default_to_everything_search(solr_params)
        expect(solr_params["q"]).to eq("*")
      end

      it "sets blacklight_params q to *" do
        search_builder.default_to_everything_search(solr_params)
        expect(search_builder.blacklight_params["q"]).to eq("*")
      end
    end

    context "with query ending in closing brace" do
      let(:query) { "word}" }

      it "appends * to q" do
        search_builder.default_to_everything_search(solr_params)
        expect(solr_params["q"]).to eq("word}*")
      end

      it "sets blacklight_params q to *" do
        search_builder.default_to_everything_search(solr_params)
        expect(search_builder.blacklight_params["q"]).to eq("*")
      end
    end

    context "with normal query" do
      let(:query) { "normal query" }

      it "does not change q" do
        search_builder.default_to_everything_search(solr_params)
        expect(solr_params["q"]).to eq("normal query")
      end

      it "does not set blacklight_params q" do
        search_builder.default_to_everything_search(solr_params)
        expect(search_builder.blacklight_params["q"]).to be_nil
      end
    end

    context "when controller is catalog" do
      let(:user_params) { { "controller" => "catalog" } }
      let(:query) { nil }

      it "sets sort to sequence asc" do
        search_builder.default_to_everything_search(solr_params)
        expect(solr_params["sort"]).to eq("sequence asc")
      end

      it "sets blacklight_params sort to sequence asc" do
        search_builder.default_to_everything_search(solr_params)
        expect(search_builder.blacklight_params["sort"]).to eq("sequence asc")
      end
    end

    context "when controller is quotes" do
      let(:user_params) { { "controller" => "quotes" } }
      let(:query) { nil }

      it "sets sort to quote_date_sort asc, author_sort asc" do
        search_builder.default_to_everything_search(solr_params)
        expect(solr_params["sort"]).to eq("quote_date_sort asc, author_sort asc")
      end
    end

    context "when controller is not in NULL_SEARCH_SORT" do
      let(:user_params) { { "controller" => "unknown" } }
      let(:query) { nil }

      it "sets sort to nil" do
        search_builder.default_to_everything_search(solr_params)
        expect(solr_params["sort"]).to be_nil
      end
    end

    context "with Solr local params ending in brace" do
      let(:query) { "{!qf=$headword_and_forms_qf pf=$headword_and_forms_pf}" }

      it "appends * to q" do
        search_builder.default_to_everything_search(solr_params)
        expect(solr_params["q"]).to eq(query + "*")
      end
    end
  end
end