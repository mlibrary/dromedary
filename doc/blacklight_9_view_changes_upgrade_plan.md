# Blacklight 9 View/Presenter Changes Upgrade Plan

Generated: June 2026. Updated after full codebase audit against the
[BL9 upgrade guide](https://github.com/projectblacklight/blacklight/wiki/Upgrading-to-Blacklight-9).

---

## Summary

The project runs Blacklight 9.0.0 + Bootstrap 5.3.8. Remaining migration work falls into
six sequenced phases. Each phase follows TDD: write failing tests first, then implement
fixes until tests pass.

| Phase | Category | Status | Depends On |
|---|---|---|---|
| 0 | Foundation (SCSS, rails-ujs) | **BROKEN** | — |
| 1 | BS4→BS5 markup migration | **BROKEN** | Phase 0 |
| 2 | Keyboard dropdown rewrite | **BROKEN** | Phase 1 |
| 3 | Solr config fixes | **BROKEN** | — |
| 4 | Autocomplete migration | **BROKEN** | Phases 2, 3 |
| 5 | Rendering pipeline review | **PENDING** | — |
| 6 | jQuery removal | **LOW** | Phases 2, 4 |

Phases 0+1+2 are sequential (asset pipeline chain). Phases 3+5 are independent.
Phase 4 depends on both chains. Phase 6 is cleanup.

---

## Dependency Graph

```
Phase 0: SCSS + rails-ujs
    |
    v
Phase 1: BS4 -> BS5 markup (26 files)
    |
    v
Phase 2: Keyboard dropdown (vanilla JS rewrite)
    |                          \
    v                           v
Phase 4: Autocomplete      Phase 3: Solr config
    |                           /
    v                          v
Phase 6: jQuery removal <------
    
Phase 5: Rendering pipeline (independent, anytime)
```

---

## Phase 0: Foundation

### 0.1 SCSS Import Path [BROKEN]

**Problem:** `@import 'blacklight-frontend/stylesheets/blacklight'` does not exist
in the BL9 Sprockets gem. This path is for importmaps only. The BL9 gem provides
`app/assets/stylesheets/blacklight/blacklight.scss` for Sprockets.

**Fix:** Revert `app/assets/stylesheets/blacklight.scss` to:
```scss
@import 'blacklight/blacklight';
```

**Reference:** [BL9 upgrade wiki item 4](https://github.com/projectblacklight/blacklight/wiki/Upgrading-to-Blacklight-9)

### 0.2 rails-ujs Deprecated [BROKEN]

**Problem:** `//= require rails-ujs` in `app/assets/javascripts/application.js` is
deprecated in Rails 7+. Zero `remote: true` or `data: { confirm: ... }` patterns exist.

**Fix:** Remove `//= require rails-ujs` from `application.js`.

### Phase 0 — TDD Tests

**Failing tests to write first:**

1. **`spec/system/asset_loading_spec.rb`** — new file
   ```ruby
   # SCSS compiles without error
   it 'loads blacklight stylesheets without 404' do
     visit '/'
     # Page loads, no asset 500s in logs
     expect(page.status_code).to eq 200
     # Check that BL stylesheets are referenced (not blacklight-frontend path)
     expect(page.html).not_to include('blacklight-frontend/stylesheets')
   end

   # rails-ujs not loaded
   it 'does not load rails-ujs' do
     visit '/'
     expect(page.html).not_to include('rails-ujs')
   end
   ```

2. **`spec/views/blacklight.scss_spec.rb`** — compile-time check
   ```ruby
   it 'imports blacklight/blacklight (not blacklight-frontend)' do
     content = File.read(Rails.root.join('app/assets/stylesheets/blacklight.scss'))
     expect(content).to include("blacklight/blacklight")
     expect(content).not_to include("blacklight-frontend")
   end
   ```

**Verification:** `bundle exec rspec spec/system/asset_loading_spec.rb` — all green.

---

## Phase 1: BS4→BS5 Markup Migration

### Pattern Replacements

| BS4 Pattern | BS5 Replacement | Files |
|---|---|---|
| `sr-only` | `visually-hidden` | 22 files |
| `data-toggle="collapse"` | `data-bs-toggle="collapse"` | 4 files |
| `data-target="..."` | `data-bs-target="..."` | 4 files |
| `data-dismiss="modal"` | `data-bl-dismiss="modal"` (BL9 custom) | 5 files |
| `data-dismiss="alert"` | `data-bs-dismiss="alert"` | 2 files |
| `.close` button class | `.btn-close` (+ `blacklight-modal-close` for modals) | 5 files |

### File List

**Catalog views:**
- `app/views/catalog/_search_form.html.erb` — `sr-only`, `data-toggle`
- `app/views/catalog/_home_header_navbar.html.erb` — `data-toggle`, `data-target`, `sr-only`
- `app/views/catalog/_sort_widget.html.erb` — `data-toggle`, `btn-secondary dropdown-toggle`
- `app/views/catalog/_constraints_element.html.erb` — `sr-only`
- `app/views/catalog/_index_header_entry.html.erb` — `sr-only`
- `app/views/catalog/index.html.erb` — `sr-only`
- `app/views/catalog/show.html.erb` — `sr-only`

**Application views:**
- `app/views/application/_search_form.html.erb` — `sr-only`
- `app/views/application/_facets.html.erb` — `data-toggle`, `data-target`, `sr-only`
- `app/views/application/_facet_layout.html.erb` — `data-toggle`, `data-target`
- `app/views/application/_sort_widget.html.erb` — `data-toggle`, `btn-secondary dropdown-toggle`
- `app/views/application/_search_results.html.erb` — `sr-only`
- `app/views/application/_view_type_group.html.erb` — `sr-only`
- `app/views/application/_constraints_element.html.erb` — `sr-only`
- `app/views/application/facet.html.erb` — `data-dismiss`, `.close`
- `app/views/application/email.html.erb` — `data-dismiss`, `.close`
- `app/views/application/email_success.html.erb` — `data-dismiss`, `.close`
- `app/views/application/sms.html.erb` — `data-dismiss`, `.close`
- `app/views/application/sms_success.html.erb` — `data-dismiss`, `.close`
- `app/views/application/citation.js.erb` — `data-dismiss`, `.close`

**Other views:**
- `app/views/_flash_msg.html.erb` — `data-dismiss`, `.close`
- `app/views/bibliography/_search_results.html.erb` — `sr-only`
- `app/views/bibliography/index.html.erb` — `sr-only`
- `app/views/bibliography/show.html.erb` — `sr-only`
- `app/views/quotes/_search_results.html.erb` — `sr-only`
- `app/views/quotes/index.html.erb` — `sr-only`
- `app/views/contacts/create.html.erb` — `data-dismiss`

### Phase 1 — TDD Tests

**Failing tests to write first:**

1. **`spec/system/bs5_compliance_spec.rb`** — new file
   ```ruby
   # No BS4 sr-only class anywhere
   it 'uses visually-hidden instead of sr-only' do
     visit '/'
     expect(page).not_to have_css('.sr-only')
     expect(page).to have_css('.visually-hidden')
   end

   # BS5 data attributes
   it 'uses data-bs-toggle instead of data-toggle' do
     visit '/dictionary'
     expect(page).not_to have_selector('[data-toggle]')
     expect(page).to have_selector('[data-bs-toggle]')
   end

   # BL9 modal dismiss
   it 'uses data-bl-dismiss for modals' do
     # Trigger a modal (e.g., email) and check attribute
     visit '/'
     expect(page).not_to have_selector('[data-dismiss="modal"]')
   end
   ```

2. **`spec/views/bs4_patterns_spec.rb`** — grep-based code audit
   ```ruby
   it 'has no sr-only in view files' do
     files = Dir.glob(Rails.root.join('app/views/**/*.erb'))
     offenders = files.select { |f| File.read(f).match?(/\bsr-only\b/) }
     expect(offenders).to be_empty, "sr-only found in: #{offenders.join(', ')}"
   end

   it 'has no data-toggle (without bs) in view files' do
     files = Dir.glob(Rails.root.join('app/views/**/*.erb'))
     offenders = files.select { |f| File.read(f).match?(/data-toggle(?!.*data-bs-toggle)/) }
     expect(offenders).to be_empty, "data-toggle found in: #{offenders.join(', ')}"
   end
   ```

**Verification:** `bundle exec rspec spec/system/bs5_compliance_spec.rb spec/views/bs4_patterns_spec.rb` — all green.

---

## Phase 2: Keyboard Dropdown Rewrite

### Problem

The keyboard special character dropdown (Þ þ, Ð ð, Ʒ ʒ, Æ æ) is implemented in
`app/assets/javascripts/static.js` using jQuery. It exists in legacy partials
`catalog/_search_form.html.erb` and `application/_search_form.html.erb`, but BL9's
`SearchBarComponent` renders its own template and does NOT include these partials.

The keyboard dropdown is not rendered on any page currently.

### Fix

1. Rewrite `app/assets/javascripts/static.js` in vanilla JS (no jQuery)
2. Wire the keyboard dropdown into BL9's `SearchBarComponent` using the `append` slot
3. Update the home page templates to include the keyboard dropdown via the component slot

### BL9 SearchBarComponent Slots

```erb
<%= render Blacklight::SearchBarComponent.new(
  url: search_action_url,
  params: params
) do |component| %>
  <% component.with_append do %>
    <!-- keyboard dropdown goes here -->
  <% end %>
<% end %>
```

### Phase 2 — TDD Tests

**Failing tests to write first:**

1. **`spec/system/keyboard_dropdown_spec.rb`** — new file
   ```ruby
   shared_examples 'keyboard dropdown' do
     it 'renders special character buttons' do
       expect(page).to have_css('.keyboard')
       expect(page).to have_content('Þ')
       expect(page).to have_content('Ð')
       expect(page).to have_content('Ʒ')
       expect(page).to have_content('Æ')
     end
   end

   context 'dictionary home' do
     before { visit '/dictionary' }
     include_examples 'keyboard dropdown'
   end

   context 'bibliography home' do
     before { visit '/bibliography' }
     include_examples 'keyboard dropdown'
   end

   context 'quotations home' do
     before { visit '/quotations' }
     include_examples 'keyboard dropdown'
   end

   context 'header search bar' do
     before { visit '/dictionary?q=test&search_field=hnf' }
     include_examples 'keyboard dropdown'
   end
   ```

2. **`spec/javascripts/keyboard_vanilla_spec.rb`** — no jQuery dependency
   ```ruby
   it 'does not use jQuery for keyboard dropdown' do
     content = File.read(Rails.root.join('app/assets/javascripts/static.js'))
     expect(content).not_to match(/\$\(/)
     expect(content).not_to match(/jQuery/)
   end
   ```

**Verification:** `bundle exec rspec spec/system/keyboard_dropdown_spec.rb` — all green.

---

## Phase 3: Solr Config Fixes

### Problem

The `/quotesearch` handler and potentially the `/search` handler fail with
"Neither qf nor df are present" when using per-field `solr_local_parameters`
with `$variable` syntax (e.g., `{type: "edismax", qf: "$quote_everything_qf"}`).

The `$variable` resolution from handler defaults may behave differently in Solr 10.

### Diagnosis Steps

1. Test each Solr handler directly:
   ```bash
   # Dictionary search (known to work for some queries)
   curl "http://localhost:8983/solr/dromedary/search?q=test&qf=everything&defType=edismax"
   
   # Quote search (known to fail)
   curl "http://localhost:8983/solr/dromedary/quotesearch?q=test&defType=edismax&qf=\$quote_everything_qf"
   
   # Bibliography search
   curl "http://localhost:8983/solr/dromedary/bibsearch?q=test&defType=edismax&qf=\$bib_everything_qf"
   ```

2. Check if `$variable` resolution works from handler defaults in Solr 10
3. If not, convert to explicit `qf` values in `solr_local_parameters`

### Potential Fix

Replace variable references with explicit values in controller configs:

```ruby
# Before (relies on $variable from handler defaults)
config.add_search_field('quote_everything') do |field|
  field.solr_local_parameters = {
    type: "edismax",
    qf: "$quote_everything_qf",
    pf: "$quote_everything_pf"
  }
end

# After (explicit values)
config.add_search_field('quote_everything') do |field|
  field.solr_local_parameters = {
    type: "edismax",
    qf: "quote^10 citation^5 ...",  # from quote_searches/quote_everything_search.xml
    pf: "quote^50 citation^20 ..."
  }
end
```

### Phase 3 — TDD Tests

**Failing tests to write first:**

1. **`spec/system/search_handlers_spec.rb`** — new file
   ```ruby
   it 'dictionary search returns results' do
     visit '/dictionary?q=women&search_field=everything'
     expect(page.status_code).to eq 200
     expect(page).to have_css('.document')
   end

   it 'bibliography search returns results' do
     visit '/bibliography?q=women&search_field=bib_keyword'
     expect(page.status_code).to eq 200
     expect(page).to have_css('.document')
   end

   it 'quotations search returns results' do
     visit '/quotations?q=women&search_field=quote_everything'
     expect(page.status_code).to eq 200
     expect(page).to have_css('.document')
   end
   ```

2. **`spec/solr/handler_spec.rb`** — direct Solr tests
   ```ruby
   it 'quotesearch handler resolves $quote_everything_qf' do
     response = SolrDocument.connection.get('quotesearch', params: {
       q: 'test', defType: 'edismax', qf: '$quote_everything_qf'
     })
     expect(response['response']['numFound']).to be > 0
   end
   ```

**Verification:** `bundle exec rspec spec/system/search_handlers_spec.rb` — all green.

---

## Phase 4: Autocomplete Migration

### Problem

`autocomplete.js.erb` uses jQuery Typeahead.js + Bloodhound, but
`twitter-typeahead-rails` is not in the Gemfile. The autocomplete feature is broken.

BL9 provides a native `<auto-complete>` web component that the `SearchBarComponent`
renders when `autocomplete_path` is set.

### Fix

1. Delete `app/assets/javascripts/blacklight/autocomplete.js.erb`
2. Configure `config.autocomplete_enabled = true` in `catalog_controller.rb`
3. Ensure `config.autocomplete` points to Solr suggest handlers
4. Update Solr suggest handlers to return HTML `<li>` fragments (not JSON)
5. Remove `.twitter-typeahead` CSS rules from `main.scss`

### Solr Suggest Handler Response Format

BL9 `<auto-complete>` expects HTML `<li>` fragments:
```html
<li role="option" data-autocomplete-value="MED12345">winnen</li>
```

Current handlers return JSON. Need to add a `suggest.template` or custom response writer.

### Phase 4 — TDD Tests

**Failing tests to write first:**

1. **`spec/system/autocomplete_spec.rb`** — new file
   ```ruby
   it 'renders auto-complete element on dictionary search' do
     visit '/dictionary'
     expect(page).to have_css('auto-complete')
   end

   it 'suggest endpoint returns HTML li fragments' do
     visit '/catalog/suggest.json?search_field=h&q=win'
     # Or test the endpoint directly
     response = Net::HTTP.get(URI('http://localhost:3000/catalog/suggest?search_field=h&q=win'))
     expect(response).to include('<li')
   end
   ```

2. **`spec/views/autocomplete_config_spec.rb`** — config checks
   ```ruby
   it 'has autocomplete enabled' do
     expect(CatalogController.blacklight_config.autocomplete_enabled).to be true
   end

   it 'does not reference Typeahead.js' do
     js_files = Dir.glob(Rails.root.join('app/assets/javascripts/**/*.js'))
     offenders = js_files.select { |f| File.read(f).match?(/typeahead|bloodhound/i) }
     expect(offenders).to be_empty
   end
   ```

**Verification:** `bundle exec rspec spec/system/autocomplete_spec.rb` — all green.

---

## Phase 5: Rendering Pipeline Review

### Problem

BL9's rendering pipeline always returns arrays. Multi-valued Solr fields now
render as separate `<dd>` elements instead of a single joined string.

### Action

Review all `doc_presenter.field_value` calls in views. Add `join: true` to field
configurations where multi-valued fields should display as a single joined string:

```ruby
config.add_index_field 'field_name', label: 'Label', join: true
```

### Files to Check

- `app/views/catalog/_index_default.html.erb`
- `app/views/catalog/_show_default.html.erb`
- `app/views/bibliography/_index_bib.html.erb`
- `app/views/bibliography/_show_bib.html.erb`
- `app/views/quotes/_index_default.html.erb`

### Phase 5 — TDD Tests

**Failing tests to write first:**

1. **`spec/system/multi_value_rendering_spec.rb`** — new file
   ```ruby
   it 'renders multi-valued fields as joined string on index' do
     visit '/dictionary?q=women&search_field=everything'
     # Check that result cards don't have duplicate field labels
     first('.document') do |doc|
       # Each field label should appear once, not once per value
       expect(doc).to have_css('dt', count: 1..10)  # reasonable range
     end
   end
   ```

**Verification:** `bundle exec rspec spec/system/multi_value_rendering_spec.rb` — all green.

---

## Phase 6: jQuery Removal

### Prerequisites

- Phase 2 complete (keyboard dropdown rewritten in vanilla JS)
- Phase 4 complete (autocomplete no longer needs jQuery)

### Action

1. Remove `jquery-rails` from Gemfile (line 197)
2. Remove `//= require jquery` from `application.js`
3. Refactor `app/views/_home_text.html.erb` toggle to vanilla JS
4. Run `bundle install`

### Phase 6 — TDD Tests

**Failing tests to write first:**

1. **`spec/system/no_jquery_spec.rb`** — new file
   ```ruby
   it 'does not load jQuery' do
     visit '/'
     expect(page.html).not_to include('jquery')
   end

   it 'home text toggle still works without jQuery' do
     visit '/'
     expect(page).to have_css('.home-text-toggle')
     # Click and verify content toggles
   end
   ```

2. **`spec/views/jquery_free_spec.rb`** — code audit
   ```ruby
   it 'has no jQuery references in JS files' do
     js_files = Dir.glob(Rails.root.join('app/assets/javascripts/**/*.{js,erb}'))
     offenders = js_files.select { |f| File.read(f).match?(/\$\(|jQuery/) }
     expect(offenders).to be_empty, "jQuery found in: #{offenders.join(', ')}"
   end
   ```

**Verification:** `bundle exec rspec spec/system/no_jquery_spec.rb spec/views/jquery_free_spec.rb` — all green.

---

## Already Compliant

### DocumentComponent usage
`_show_main_content.html.erb` passes `document_presenter(@document)` to
`document_component.new(document: ...)` — correct BL9 pattern.

### DocumentTitleComponent usage
Title slot uses `component.with_title(as: 'h1', classes: '', link_to_document: false, actions: false)` — correct BL9 pattern.

### DocumentComponent in index views
`_document.html.erb` passes `document_presenter(document)` to `document_component.new(document: ...)` — correct.

### Email/Sms removed
No extensions found in `solr_document.rb`. Already removed from `catalog_controller.rb`.

### Presenter pattern
Custom presenters use `SimpleDelegator` wrapping `Blacklight::IndexPresenter` — compatible with BL9.

### Header/Constraints components
`_header_navbar.html.erb` uses `Blacklight::SearchBarComponent` directly. Constraints use
`Blacklight::ConstraintsComponent.new` directly. Both are BL9 patterns.

---

## Live Reference Pages

Reference pages captured from the live production system (`quod.lib.umich.edu`) on 2026-06-01.
Stored in `doc/bootstrap_upgrade/reference_pages/` for visual/structural comparison during upgrade.

| Page Type | URL |
|---|---|
| Splash/Home | `https://quod.lib.umich.edu/m/middle-english-dictionary/` |
| Dictionary landing | `https://quod.lib.umich.edu/m/middle-english-dictionary/dictionary` |
| Dictionary search results | `https://quod.lib.umich.edu/m/middle-english-dictionary/dictionary?utf8=%E2%9C%93&search_field=hnf&q=wymmen` |
| Dictionary show (winnen) | `https://quod.lib.umich.edu/m/middle-english-dictionary/dictionary/MED52917` |
| Bibliography landing | `https://quod.lib.umich.edu/m/middle-english-dictionary/bibliography` |
| Bibliography search results | `https://quod.lib.umich.edu/m/middle-english-dictionary/bibliography?utf8=%E2%9C%93&search_field=bib_keyword&q=women` |
| Bibliography show (BIB628) | `https://quod.lib.umich.edu/m/middle-english-dictionary/bibliography/BIB628` |
| Quotations landing | `https://quod.lib.umich.edu/m/middle-english-dictionary/quotations` |
| Quotations search results | `https://quod.lib.umich.edu/m/middle-english-dictionary/quotations?utf8=%E2%9C%93&search_field=quote_everything&q=women` |

**Note:** Show page URLs contain tracking params that expire. Strip when comparing.

---

## Appendix A: Resolved Items

- [x] Bootstrap 5 column classes in `layout_helper_behavior.rb`
- [x] Archived views deleted (`original_blacklight_views/`)
- [x] `UpdatesController` and views deleted
- [x] Print view deferred (not deleted)
- [x] Advanced search explicitly disabled
- [x] `input-group-addon` → `input-group-text` in SCSS and views
- [x] Sass variables migrated to CSS custom properties
- [x] Dead Sass variables removed

## Appendix B: Additional Notes

### jQuery Dependency

BL9 dropped jQuery entirely. The project's `jquery-rails` gem (Gemfile line 197)
is not used by Blacklight — only by project-specific code.

**jQuery usage in project:**

| File | Usage |
|---|---|
| `app/assets/javascripts/static.js` | Keyboard special character dropdown |
| `app/views/_home_text.html.erb` | About section toggle |
| `app/assets/javascripts/blacklight/autocomplete.js.erb` | Typeahead.js/Bloodhound |

**Plan:** Remove jQuery after Phases 2 and 4 (see Phase 6).
