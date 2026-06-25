# a_search

**STATUS: FINISHED** — Remaining difference is native BS5 select dropdown caret
style (larger chevron vs ORIG's small double-caret). Acceptable BS5 behavior.

## Changes

### 1. Fix "Limit your search" facets heading (COMMON / facets)
- **Problem:** "Limit your search" rendered at 28.5px with no surrounding box;
  orig is 19px inside a bordered gray panel (matching the "Part of Speech"
  scale).
- **Cause:** Blacklight 9 changed the facets markup to
  `.facets-header > h2.facets-heading.h4`. BS5's `.h4` utility forces
  `font-size:28.5px`, and the old box was gone. The existing `main.scss` rule
  only targeted the old BL8 DOM (`.top-panel-heading.panel-heading
  h2.facets-heading`), so it no longer matched.
- **Fix:** Extended that rule to also match `.facets-header`, restored the gray
  box (`#FAFAFA` bg, `1px solid #ddd`, padding), and reset the heading to
  `font-size:1em; margin:0` to override the `.h4` utility.
- **File:** `app/assets/stylesheets/main.scss`.
- **DOM:** unchanged (BL9 markup is the legitimate upgraded structure).
- **Scope:** COMMON — all faceted search pages. Do not reapply.

### 2. Recompose the pagination/sort/per-page toolbar + constraint chip (COMMON)
- **Problem:** Orig showed a single ~61px toolbar row: small pagination text on
  the left, a compact white "a x" constraint chip, and white-bg/blue-text
  "Sort by Relevance" + "20 per page" buttons floated right. Port instead:
  - rendered a large "Your selections:" box (with Start Over button) at the top
    of the sidebar;
  - broke the toolbar into 3 stacked rows (~174px);
  - styled the chip green/oversized (19px) and the buttons gray
    (`btn-secondary`).
- **Causes (BL8 -> BL9 + BS3 -> BS5):**
  - This app's `catalog/index.html.erb` rendered `'constraints'` inside
    `#sidebar`. BL9's new `Blacklight::ConstraintsComponent` turns that into a
    full labeled box (`Your selections:` `<h2>` + Start Over). Orig (BL8)
    rendered the constraint as a bare inline chip in the content toolbar's
    empty `<span class="search-term-filter">` next to pagination.
  - BL9 wraps the pager in `<nav class="paginate-section">` (block, full-width)
    and tags the widgets with BS4 `.float-right`/`.pull-right` classes that no
    longer float in BS5 -> each piece dropped onto its own line.
  - Chip used BL9's green `btn-outline-secondary` styling; buttons used BS5's
    gray `btn-secondary`.
- **DOM decision (approved):** moved the constraints render out of `#sidebar`
  and into the toolbar's `search-term-filter` span to match orig's placement.
  Kept BL9's ConstraintsComponent markup but hid its "Your selections:" label
  and Start Over button via CSS (orig had neither).
- **Fix:**
  - `app/views/catalog/index.html.erb`: removed `<%= render 'constraints' %>`
    from `#sidebar`.
  - `app/views/catalog/_sort_and_per_page.html.erb`: rendered
    `'constraints'` into the `search-term-filter` span.
  - `app/assets/stylesheets/main.scss`:
    - `#sortAndPerPage` -> `display:flex; flex-wrap:wrap; align-items:center`;
      `.paginate-section` shrunk to `width:auto`; `.search-widgets` set to
      `float:none; margin-left:auto` (BS5 has no `.pull-right`); toolbar
      dropdown toggles re-skinned white-bg/blue-text/~14px.
    - Constraint chip restyled white-bg / `#333` text / thin gray border / 12px
      / centered contents (`align-items/justify-content:center; line-height:1`),
      remove-icon SVG sized to 12px, and `#appliedParams` margin zeroed
      (`!important`) to override BL9's `mb-2` so the chip centers in the row.
    - Hid `.constraints-label`, `#startOverLink`, `.start-over`,
      `a.btn.catalog_startOverLink`.
- **Scope:** COMMON — affects the catalog search toolbar. The same sidebar
  `render 'constraints'` pattern also exists in `bibliography/index.html.erb`
  and `quotes/index.html.erb`; those will need the same view move when their
  pages are worked (the SCSS is already shared/common).

### 4. Hide native browser search clear button (COMMON / UX -- REVIEW)
- **Problem:** PORT3000's search input displayed a circled ⊗ clear button inside
  the text field; ORIG had none.
- **Cause:** BL9 or the autocomplete component changed the input `type` from
  `"text"` to `"search"`, which triggers the browser's native clear button.
- **Fix:** Added CSS to hide `::-webkit-search-cancel-button` and
  `::-webkit-search-decoration` with `appearance: none` (same approach ORIG used
  via normalize.css rules).
- **File:** `app/assets/stylesheets/main.scss`.
- **DOM:** unchanged.
- **Scope:** COMMON — affects all search forms site-wide. Do not reapply.
- **UX NOTE:** This matches ORIG behavior, but the native clear button is
  arguably useful. Review whether to keep this hidden or restore it.

### 3. Re-skin the facet field heading + collapse caret (COMMON / facets)
- **Problem:** Each facet heading (e.g. "Part of Speech") rendered as a BS5
  accordion button: oversized (62px tall), blue link-colored bold text, and a
  thick BS5 SVG chevron that rotated up when expanded. Orig (BL8) was a compact
  48px gray panel heading with dark-gray text and a small caret that pointed
  **right when closed** and **down when open**.
- **Cause:** Blacklight 9 renders facet headings as
  `h3.facet-field-heading > button.accordion-button` (BS5 accordion). The
  default `.accordion-button` styling (font color, size, padding, chevron
  `::after`) replaced orig's `.collapse-toggle.panel-heading` markup.
- **Fix (`app/assets/stylesheets/main.scss`):** Added a
  `.facet-field-heading .accordion-button` rule — gray text (`#4A4A4A`),
  `font-size:1em`, `font-weight:600`, `padding:10px 15px`, `box-shadow:none`,
  `#FAFAFA` bg. Replaced BS5's SVG chevron `::after` with a CSS-border caret:
  down-pointing when expanded (`&:not(.collapsed)`), right-pointing when
  collapsed (`&.collapsed`) — matching orig's open/closed convention.
- **DOM:** unchanged (BL9 accordion markup is the legitimate upgrade).
- **Scope:** COMMON — all faceted search pages. Do not reapply.
