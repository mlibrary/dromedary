# quote_search — CHANGES

URL: /m/middle-english-dictionary/quotations?search_field=quote_everything&q=women

## Change 1: Remove "Advanced search" link

- Element: `a.advanced_search` rendered below the search bar.
- Symptom: port3000 showed an "Advanced search" link absent in orig.
- Cause: Blacklight 9 enables advanced search by default. `CatalogController`
  and `BibliographyController` already disabled it, but `QuotesController`
  did not.
- DOM diff: link is server-rendered by BL9; no CSS can remove cleanly. Same
  family as bib_splash Change 2.
- Fix (`app/controllers/quotes_controller.rb`): added
  `config.advanced_search.enabled = false` in the `configure_blacklight`
  block, matching the catalog/bibliography controllers.
- Status: Accepted by user.

## Change 2: Restore inline toolbar query-constraint chip

- Element: toolbar chip `.search-term-filter #appliedParams .constraint-value`
  ("Quotation including citation > women X") next to "1 - 91 of 91".
- Symptom: port3000 had no inline constraint chip in the results toolbar; the
  only constraint surfaced in the BL9 "Current Filters" sidebar.
- Cause: `QuotesController` has no `app/views/quotes/_sort_and_per_page.html.erb`,
  so it fell back to `application/_sort_and_per_page.html.erb`, which (unlike the
  `catalog/` and `bibliography/` variants) does NOT render the
  `.search-term-filter` query-constraint chip. Without that wrapper, the
  toolbar-chip CSS in main.scss had nothing to target.
- DOM diff: orig (BL6) rendered the chip in the toolbar via
  `application/_sort_and_per_page`; BL9 moved query constraints to the sidebar
  component. Restored the toolbar chip to match orig blueprint (same approach
  as bibliography search results).
- Fix: added `app/views/quotes/_sort_and_per_page.html.erb` mirroring
  `bibliography/_sort_and_per_page.html.erb` (renders
  `<span class="search-term-filter"><%= render 'catalog/query_constraint' %></span>`).
  Existing CSS (`#sidebar #appliedParams .constraint.query { display:none }`)
  keeps the sidebar from duplicating the query chip.
- Result: chip renders `Quotation including citation > women X` (BL9 caret
  separator + SVG x-icon, both previously accepted on dictionary/bib pages).
- Status: Accepted by user.

## Change 3: Hide spurious "Current Filters / Start Over" sidebar panel

- Element: `#sidebar .constraints-container` ("Current Filters" heading +
  "Start Over" link) in the left column.
- Symptom: port3000 rendered a "Current Filters / Start Over" panel in the
  sidebar; orig had no sidebar panel at all (results sat against an empty
  sidebar column).
- Cause: Quotations search defines no facet fields, so orig (BL6) left the
  sidebar empty. BL9 always renders a constraints panel (with Start Over) in
  the sidebar; the query chip there is already CSS-hidden, leaving an empty
  "Current Filters" box with no purpose on quotes pages.
- DOM diff: BL9 component-rendered; no facets exist to justify the panel.
  Hidden via CSS to match orig.
- Fix (`app/assets/stylesheets/main.scss`): scoped by body class
  `.blacklight-quotes #sidebar .constraints-container { display: none; }`.
  Does not affect catalog/bibliography (which have real facets) or the inline
  toolbar chip (rendered in `#sortAndPerPage .search-term-filter`).
- Status: Accepted by user.

---

**STATUS: FINISHED** — all changes signed off by user.
