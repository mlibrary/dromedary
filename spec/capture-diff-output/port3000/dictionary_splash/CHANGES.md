# dictionary_splash — ✓ FINISHED

Common header/global fixes from `splash` already apply here (font-size,
container 60rem centering, secondary-nav stripe). See splash/CHANGES.md.

## Accepted changes

### 1. Restore 3-column layout in `.fact-panel` detail section

- **Element:** bottom detail columns ("How to get started / More ways to
  search / History of the MED").
- **Problem:** columns stacked vertically instead of sitting in a row.
- **Cause:** orig is Bootstrap 3 (
  `.col-sm-4 { float:left; width:33.33% }`);
  port is Bootstrap 5 (`.col-sm-4 { flex:0 0 auto; width:33.33% }`) which
  needs
  a flex `.row` parent. The wrapper `.col-sm-12.padding0` is
  `display:block`,
  so the 33%-wide columns stacked.
- **DOM:** identical both sides — pure grid-engine difference, no DOM
  change.
- **Fix:**
  `.fact-panel .col-sm-12.padding0 { display:flex; flex-wrap:wrap }`.
- **File:** `app/assets/stylesheets/main.scss`.

### 2. Remove gray whitespace under nav (full-bleed banner page)

- **Problem:** gray strip + whitespace between white nav and the banner.
- **Cause:** Blacklight default `main { padding-block: ~9.5px }` exposed
  the
  gray body background below the full-bleed banner. Body here is
  `blacklight-catalog-home` (not `-splash`), so the splash-scoped rule
  missed it.
- **DOM:** `<main id="main-content">` kept (a11y landmark / skip-link
  target).
- **Fix:** extended the rule to also match
  `.blacklight-catalog-home #main-content { padding-block:0 }`.
- **File:** `app/assets/stylesheets/main.scss`.

### 3. Fix banner image-attribution caption font (COMMON banner element)

- **Element:** `.banner-text--caption` ("Image: The Ellesmere
  Manuscript...").
- **Cause:** port set `font-size: .85em` (-> 16.15px); orig computes
  10.45px = `.55em`.
- **Fix:** `.banner-text--caption { font-size: .55em }`.
- **File:** `app/assets/stylesheets/main.scss`.
- **Scope:** COMMON banner element (also on splash banner) - matches orig
  globally.

### 6. Fix oversized "Search" button label (home search bar)

- **Element:** `.search-bar--home button#search` / `.submit-search-text`.
- **Problem:** "Search" label rendered 19px; orig is 17.5px.
- **Cause:** BS3 `.btn` base was 14px with a `1.25em` label (-> 17.5px).
  BS5
  `.btn` inherits the 19px body size, and the home search bar never
  re-declared
  the button base size or the `1.25em` label rule (only
  `.search-bar--header` had it).
- **DOM:** identical except port adds responsive utility classes
  (`d-none d-md-inline me-sm-1`) to hide the label on small screens --
  kept.
- **Fix:** scoped to `.search-bar--home`:
  `button#search { font-size:14px }` +
  `.submit-search-text { font-size:1.25em }` -> computes to orig
  14px/17.5px.
- **File:** `app/assets/stylesheets/main.scss`.

### 7. Restore gutter padding on fact-panel detail columns

- **Element:** `.fact-panel .col-sm-4` (the three detail columns).
- **Problem:** columns had 0 padding -- text butted against the container
  edge
  and adjacent columns; orig has `padding: 0 15px`.
- **Cause:** fix #1 made the wrapper `.col-sm-12.padding0` a flex container
  (not a BS5 `.row`), so the column children never received Bootstrap's
  gutter
  padding (BS3 gave `.col-sm-4` a 0 15px gutter via its base rule).
- **DOM:** identical both sides -- pure grid-engine difference.
- **Fix:** `.fact-panel .col-sm-4 { padding: 0 15px }` -> matches orig.
- **File:** `app/assets/stylesheets/main.scss`.

### 8. Fix search input focus causing layout shift

- **Element:** `.search-bar--home .form-control` (the search input field).
- **Problem:** clicking in the search box made it grow slightly (~6px),
  pushing
  the content below it down.
- **Cause:** the `:focus` rule changed `border: 1px -> 3px`, which reflowed
  the
  search row since the input height wasn't truly pinned.
- **Fix:** keep border width stable at 1px, render the yellow focus
  emphasis as
  a `box-shadow: 0 0 0 2px var(--u-m-yellow)` ring instead (no layout
  shift).
  Also applied same fix to `#dropdownMenuButton` keyboard button (was 1px->
  2px).
- **File:** `app/assets/stylesheets/main.scss`.
- **Verified:** live probe shows `focusShiftPx: 0` (was 5.875).

### 9. Fix typeahead dropdown items appearing doubled/blurry

- **Element:** `.search-autocomplete-wrapper ul.dropdown-menu` suggestion
  popup.
- **Problem:** typeahead items looked vaguely "doubled" and blurry when
  they
  appeared.
- **Cause:** the popup `<li>` items inherited `text-shadow: 1px 1px #000`
  from
  the banner/home bar container, creating a black offset shadow on light
  text.
- **Fix:** reset `text-shadow: none` on the popup (mirroring the existing
  `.keyboard-list` reset) + set opaque `background-color: #fff`.
- **File:** `app/assets/stylesheets/main.scss`.
- **Verified:** live probe shows `liShadow: "none"` (was "rgb(0,0,0) 1px
  1px").

## Note on remaining text differences

- Per user direction, font-FACE differences are IGNORED. Computed font
  sizes
  already match orig (heading 25.65px, body 19px, hero 28.5px). The wider/
  heavier look of port body text is the Helvetica fallback vs orig's Source
  Sans Pro, which also causes different line wrapping -- not a size bug.

## Still open (next iterations)

- (resolved) fact-panel container full-width -> fixed at the source by the
  COMMON `.container--full { max-width: 60rem }` change (see
  splash/CHANGES.md
  item 2). The fact-panel wrapper (`.container.container--full`) now
  centers in
  the same 60rem container as the header/hero -- no per-element override
  and no
  hardcoded px. Earlier notes here described a 1170px container; that 1170
  was
  a Bootstrap 3 computed artifact, not a declared rule, and is
  intentionally
  not reproduced.

### 4. Search-field select sizing (search row)

- **Cause:** port `.form-select` inherited the 19px body font and
  flex-stretched
  to ~456px; orig dropdown is 16px and content-sized (272px).
- **Fix:** `.search-bar--home select.form-select { font-size:16px; flex:0 0 auto;
  width:auto }` -> now 287px @ 16px.
- **File:** `app/assets/stylesheets/main.scss`.

### 4. Search-field select sizing (search row)

- **Cause:** port `.form-select` inherited the 19px body font and
  flex-stretched
  to ~456px; orig dropdown is 16px and content-sized (272px).
- **Fix:** `.search-bar--home select.form-select { font-size:16px; flex:0 0 auto;
  width:auto; padding:9px 36px 9px 16px }` -> ~287px @ 16px, with right
  padding
  so the BS5 caret doesn't overlap the longer default label.
- **File:** `app/assets/stylesheets/main.scss`.

### 5. Default dropdown option (COMPONENT fix, not CSS) [COMMON]

- **Cause:** Blacklight 9's `SearchBarComponent` selects the field only
  from
  `params[:search_field]`. On landing pages there is no such param, so the
  `<select>` fell back to its first option ("Entire entry"), ignoring the
  `default: true` field in `catalog_controller.rb:214`. Orig (BL7)
  pre-selected
  the configured default.
- **DOM/logic decision:** config is correct; only BL7->9 rendering changed.
  Restoring orig behavior is a real functional fix, done via component
  override
  (not CSS).
- **Fix:** `config/initializers/blacklight_search_bar_default_field.rb`
  prepends
  a module that, in the component's `before_render`, sets `@search_field`
  to the
  configured default field when none is supplied. Requires a Rails restart.
- **Scope:** COMMON - covers all four search bars (dictionary/bibliography/
  quotations home + header).
