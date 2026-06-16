# Stuff To Do — Dromedary

Tasks useful to this repo AND useful for testing an automated tool-routing system.
Each task includes enough context for a different agent to pick it up.

## Context for the Routing System

The pi agent harness at `~/devel/ai/experimental_pi_setup` has a forced tool-routing
system under development. It needs real-world tasks to test and calibrate against.
Dromedary is a good test target because:

- Ruby on Rails 8.1 + Blacklight 9 — complex enough to need multiple tool types
- Solr-backed search with custom query preprocessing
- XSLT-based entry rendering via presenters
- Sparse test coverage — lots of room to add value
- Multiple code layers (controllers, models, presenters, helpers, indexer) that
  exercise different routing paths

The routing system classifies tasks into phases (explore → decide → implement → validate)
and routes to appropriate tools (search_symbols, find_references, refactor, read, write, etc).
Tasks that span multiple phases and require different tool types are best for calibration.

---

## Task 1: SearchBuilder Unit Tests (HIGH VALUE)

**File**: `spec/models/search_builder_spec.rb` (currently an empty shell)
**Source**: `app/models/search_builder.rb`
**Effort**: 1-2 hours
**Phases**: explore → implement → validate

### What

`SearchBuilder` has 4 query preprocessing methods with regex edge cases that need tests:

1. **`yogh_to_ezh(solr_params)`** — substitutes Ȝ/ȝ (yogh) with ʒ (ezh) in the query
2. **`escape_intersticial_parens(solr_params)`** — escapes parens in patterns like `foo(bar)` where bar is 1-3 alpha chars, using `Parens_EscapeWorthy` regex
3. **`escape_prefix_suffix_dash(solr_params)`** — escapes leading/trailing dashes (MED entries have prefixes like `-ward`)
4. **`default_to_everything_search(solr_params)`** — defaults to `*` search when q is nil, empty, or ends with `}`

### Why it matters

- The existing spec is literally empty — just sets up `subject(:search_builder)` with no tests
- These methods have real regex edge cases: Unicode characters, nested parens, multiple dashes, nil vs empty strings
- They're called on every search query — bugs here affect all search results

### Key code context

```ruby
# app/models/search_builder.rb
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include MedInstaller::Logger

  self.default_processor_chain += [:yogh_to_ezh,
    :escape_intersticial_parens,
    :escape_prefix_suffix_dash,
    :default_to_everything_search]

  Parens_EscapeWorthy = /([-\p{Alpha}])\((\p{Alpha}{1,3})\)/

  NULL_SEARCH_SORT = {
    "catalog" => "sequence asc",
    "quotes" => "quote_date_sort asc, author_sort asc"
  }

  def yogh_to_ezh(solr_params)
    solr_params["q"] = solr_params["q"]&.gsub(/[Ȝȝ]/, "ʒ")
  end

  def escape_intersticial_parens(solr_params)
    current_q = solr_params["q"]
    if current_q
      new_q = current_q.gsub Parens_EscapeWorthy, '\1\\\\(\2\\\\)'
      solr_params["q"] = new_q
    end
  end

  def escape_prefix_suffix_dash(solr_params)
    q = solr_params["q"]
    q = q&.gsub("}-", '}\\\\-')
    q = q&.gsub(/\s+-/, ' \\\\-')
    q = q&.gsub(/-\s+/, '\\\\- ')
    q = q&.gsub(/-\Z/, '\\\\-')
    solr_params["q"] = q
  end

  def default_to_everything_search(solr_params)
    q = solr_params["q"]
    if q.nil? || (q == "") || q =~ /}\Z/
      solr_params["q"] = String(q) + "*"
      blacklight_params["q"] = "*"
      solr_params["sort"] = NULL_SEARCH_SORT[blacklight_params["controller"]]
      blacklight_params["sort"] = NULL_SEARCH_SORT[blacklight_params["controller"]]
    end
  end
end
```

### Test cases to cover

**yogh_to_ezh**:
- `Ȝword` → `ʒword` (capital yogh)
- `worȝ` → `worʒ` (lowercase yogh)
- `noyogh` → `noyogh` (no change)
- `nil` → `nil` (nil-safe via `&.`)

**escape_intersticial_parens**:
- `foo(ar)bar` → `foo\(ar\)bar` (2-char paren group)
- `foo(abcdefgh)bar` → no change (>3 chars)
- `foo(123)bar` → no change (non-alpha)
- `nil` → no crash

**escape_prefix_suffix_dash**:
- `}-ward` → `}\-ward` (after closing brace)
- `word -thing` → `word \-thing` (space-dash)
- `-word` at end of string → `\-word` (trailing dash)
- `no-dash` → no change (mid-word dash)

**default_to_everything_search**:
- `nil` → `*`
- `""` → `*`
- `"word}"` → `word}*` (ends with brace)
- `"normal query"` → no change
- Verify `sort` is set from `NULL_SEARCH_SORT` for catalog controller

### Existing spec structure

```ruby
# spec/models/search_builder_spec.rb
require "rails_helper"

RSpec.describe SearchBuilder do
  let(:user_params) { {} }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:scope) { double blacklight_config: blacklight_config }
  subject(:search_builder) { described_class.new scope }
end
```

The `scope` double provides `blacklight_config`. Each processor method takes `solr_params` (a Hash with `"q"` key). Some methods also access `blacklight_params` which is the `user_params` passed to the builder.

---

## Task 2: CatalogController#suggest Spec (HIGH VALUE)

**File**: New `spec/controllers/catalog_controller_spec.rb` (doesn't exist yet)
**Source**: `app/controllers/catalog_controller.rb` lines 350-400
**Effort**: 2-3 hours
**Phases**: explore → implement → validate

### What

The `suggest` action is a custom autocomplete endpoint that:
1. Reads `search_field` param to look up per-field Solr suggest config
2. Queries Solr's suggest endpoint
3. Looks up document IDs for each suggestion term (batched, 10 at a time)
4. Returns HTML `<li>` fragments for Blacklight's `<auto-complete>` web component

It has complex error handling (rescues all exceptions → empty response) and
multiple code paths (missing config, missing Solr, no results, with/without base_url).

### Why it matters

- Recently added (commits `401f916`, `4a0239c`, `a842337`, `8c2c3da`)
- Multiple bug fixes suggest it's fragile and needs regression tests
- Complex mocking needed (Solr connection, suggest response, search response)
- No existing spec for this action

### Key code context

The method is ~50 lines with these branches:
- `search_field` defaults to `"h"` if missing
- Returns empty HTML if autocomplete config or Solr endpoint missing
- Queries Solr suggest endpoint, parses response
- If `base_url` present: batch-queries Solr to get document IDs for suggestions
- Generates `<li>` elements with `data-autocomplete-value` and optional `data-url`
- Rescues all exceptions → empty response

### Autocomplete config

Loaded from `config/autocomplete.yml`. Structure:
```yaml
h:
  solr_endpoint: "/suggest"
  search_component_name: "suggest_headword"
```

Accessed via `blacklight_config.autocomplete[search_field]`.

### Test cases to cover

1. Missing `search_field` param → defaults to "h"
2. Missing autocomplete config → empty HTML
3. Missing Solr endpoint in config → empty HTML
4. Solr returns suggestions → correct HTML `<li>` output
5. Solr raises exception → empty HTML (graceful degradation)
6. With `base_url` → suggestions include document links
7. Without `base_url` → suggestions have no links
8. Suggestion term HTML escaping (XSS prevention)

---

## Task 3: IndexPresenter Decomposition (MEDIUM VALUE)

**File**: `app/presenters/dromedary/index_presenter.rb`
**Effort**: 3-4 hours
**Phases**: explore → decide → implement → validate

### What

`Dromedary::IndexPresenter` is ~200 lines mixing several concerns:
- XSLT transforms (`form_html`, `etym_html`, `def_html`, `note_html`)
- Entry hydration from Solr JSON (`initialize`)
- Sense rendering (`sense_html`, `sense_group_html`)
- Quote formatting (`quote_html`, `quotes_for_sense`)
- Language abbreviation mapping (`language_abbreviations`, `language_mapping`)

Could be decomposed into:
- `XsltPresenter` — XSLT transform helpers
- `SensePresenter` — sense/definition rendering
- `QuoteHelper` — quote formatting and truncation

### Why it matters

- Single Responsibility Principle — presenter does too many things
- Hard to test in isolation — XSLT transforms tangled with data access
- Other presenters (`Bib::IndexPresenter`, `Quotes::IndexPresenter`) share concerns

### Key dependencies

- `MiddleEnglishDictionary::Entry` — hydrated from `document["json"]`
- `Nokogiri::XML` — parsed from `document["xml"]`
- XSLT files in `app/assets/xslt/` (via `Dromedary::XSLTUtils`)
- `HtmlTruncator` for safe HTML truncation
- `Dromedary::SmartXML` wrapper

### How to approach

1. Use `get_class_outline` to map all methods and their dependencies
2. Use `find_references` to identify callers of each method group
3. Extract one concern at a time (start with XSLT — most self-contained)
4. Run `bundle exec rspec spec/presenters/` after each extraction

---

## Task 4: AdminController Spec (MEDIUM VALUE)

**File**: New `spec/controllers/admin_controller_spec.rb` (doesn't exist yet)
**Source**: `app/controllers/admin_controller.rb`
**Effort**: 2-3 hours
**Phases**: explore → implement → validate

### What

`AdminController` manages Solr collections:
- `collections` — list available collections
- `home` — admin dashboard
- `delete` — delete a collection (with error checking)
- `check_errors` — validate collection state
- `release` — deploy a collection to production
- `force_release` — force deploy (bypasses checks)
- `enact_release` — internal method for the actual release

### Why it matters

- Critical deployment path — bugs here can break production
- No specs at all
- `delete` has error handling that should be tested
- `release`/`force_release` have different safety checks

### Key dependencies

- `MedInstaller` module (collection management)
- `Dromedary::Services` (service configuration)
- Solr collections API

### Test approach

- Mock `MedInstaller` and Solr collection operations
- Test each action for success, error, and edge cases
- Test that `force_release` bypasses checks that `release` enforces

---

## Task 5: SearchBuilder Regex Edge Cases (LOW-MEDIUM VALUE)

**File**: Same as Task 1, but focused on edge cases
**Effort**: 1 hour (subset of Task 1)
**Phases**: explore → implement → validate

### What

Focus specifically on the regex methods' edge cases:

**Parens_EscapeWorthy** (`/([-\p{Alpha}])\((\p{Alpha}{1,3})\)/`):
- Unicode letters (not just ASCII)
- Mixed case
- Adjacent paren groups
- Escaped parens in input

**Dash escaping**:
- Multiple consecutive dashes
- Unicode dashes (em-dash, en-dash)
- Dash at very start/end of string
- Dash inside Solr local params `{!qf=$foo}`

### Why separate from Task 1

Can be done independently if Task 1 is too large. Good focused task for
testing the routing system's ability to handle precise regex work.

---

## Task 6: SolrDocument Model Enrichment (LOW VALUE)

**File**: `app/models/solr_document.rb` (currently empty class)
**Effort**: 1 hour
**Phases**: explore → implement → validate

### What

`SolrDocument` is an empty class inheriting from `Blacklight::SolrDocument`.
Could add convenience methods for commonly accessed fields:
- `headword` — primary headword
- `definitions` — definition text
- `pos` — part of speech
- `etym_languages` — etymology language codes
- `entry_json` — parsed MED entry object

### Why it matters

- Reduces duplication in presenters (they all call `document.fetch("json")` etc.)
- Makes field access discoverable via IDE
- Small, safe change

### How to approach

1. Search for `document.fetch(` and `document["` patterns across presenters
2. Identify most common field accesses
3. Add convenience methods with documentation

---

## Routing System Notes

These tasks exercise different routing paths:

| Task | Primary tools needed | Phases |
|------|---------------------|--------|
| 1. SearchBuilder tests | read, write, bash (rspec) | explore → implement → validate |
| 2. Suggest spec | get_file_outline, find_references, read, write | explore → implement → validate |
| 3. Presenter decomposition | find_references, refactor, get_class_outline | explore → decide → refactor → validate |
| 4. Admin spec | get_file_outline, search_symbols, read, write | explore → implement → validate |
| 5. Regex edge cases | read, write, bash | explore → implement → validate |
| 6. SolrDocument | get_class_outline, find_references, read, write | explore → implement → validate |
