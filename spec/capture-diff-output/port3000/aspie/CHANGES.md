# aspie

## Changes

### 1. Hide BL9 page-header constraints block on show pages (COMMON / show pages)
- **Problem:** Port3000 showed "Start Over" and "Back to Search" buttons at the
  top of the main content area above the dictionary entry card. Orig had neither.
- **Cause:** Blacklight 9 renders `Blacklight::SearchContext::ServerAppliedParamsComponent`
  (`#appliedParams.constraints-container`) as part of the document page header on
  show pages. BL8 did not.
- **Fix:** Added `.show-document #appliedParams { display: none; }` to
  `app/assets/stylesheets/main.scss`.
- **DOM:** Blacklight 9 markup left in place; hidden via CSS.
- **Scope:** COMMON — applies to all document show pages (dictionary, bibliography, quotes).
  Do not reapply.

### 2. Fix search-box focus causing layout shift (header + light-bg search bars)
- **Problem:** Clicking in the Search box on the header search bar (aspie/show
  pages) shifted everything below down a few px.
- **Cause:** Same root cause as dictionary_splash fix 8 (home bar), but on the
  header bar. `.search-bar--header .form-control:focus` changed
  `border: 1px -> 3px`, adding 2px top+bottom that reflowed the search row.
  Header had it duplicated (2 identical blocks); `.search-bar--light-bg`
  (bib/quotes pages) carried the identical bug.
- **Fix:** Keep border WIDTH pinned at 1px on focus; render the yellow emphasis
  as a non-reflowing `box-shadow: 0 0 0 2px var(--u-m-yellow)` ring (+
  `border-color` change for the visual cue). Removed the duplicate header focus
  block. Applied to all three bars (header, light-bg) to match the home bar.
- **File:** `app/assets/stylesheets/main.scss`.
- **Scope:** COMMON (search bars) -- header + light-bg variants. Do not reapply.

### 3. Fix clipped text in header search-field dropdown
- **Element:** `.search-bar--header select.form-select` (the targeted-search
  `<select>`, e.g. "Headword (with alternate spellings)").
- **Problem:** the selected option text was clipped a few px at the bottom
  (descenders cut off).
- **Cause:** the header select had no `font-size`, so it inherited the 19px
  body size (orig is 16px). With `line-height: 1` in a 40px box (9px top/bottom
  padding -> ~20px content area), the 19px glyph box overflowed and clipped
  descenders. The home bar was already fixed to 16px (splash item 4); the
  header bar select was never re-sized.
- **Fix:** `font-size: 16px` (match orig) + `line-height: 1.2`
  (16 x 1.2 = 19.2px fits the 20px content box). Width is content-sized.
- **File:** `app/assets/stylesheets/main.scss`.
- **Scope:** `.search-bar--header` select. Matches orig 16px.

### 4. Fix malformed `.fund-panel ul` rule (pre-existing SCSS bug) [COMMON]
- **Problem:** `.fund-panel ul` had `min-height: 100% li { ... }` -- a missing
  semicolon after `100%` merged the declaration into the nested `li` selector,
  so the `li { width:50%; flex:0 0 50% }` 2-column funder layout never applied.
- **Fix:** `min-height: 100%;` then a proper nested `li { width:50%; flex:0 0 50% }`.
- **File:** `app/assets/stylesheets/main.scss` (line ~324).
- **Scope:** COMMON (`.fund-panel`). Not aspie-specific; pre-existing bug found
  while working this page. Do not reapply.

### 5. Fix sidebar cards rendering gray and merged (BS3 panel -> BS5 card)
- **Element:** `#sidebar .card` ("Related Dictionary Entries" / "Language
  abbreviation key" sidebar cards).
- **Problem:** the two sidebar cards rendered gray (#F2F2F2) and flush against
  each other (no gap), looking like one merged box; orig showed two separate
  white panels with a gap between them.
- **Cause (two parts):**
  1. BS5.3 defaults `$card-bg` to `$body-bg`. `bootstrap-variables.scss` sets
     `$body-bg: #F2F2F2`, so every card inherits the gray body fill. Orig BS3
     `.panel-default` was white.
  2. BS5 `.card` has no bottom margin; orig BS3 `.panel` had `margin: 0 0 20px`.
     With no gap the two cards touched and read as one box.
- **DOM:** changed BS3 `.panel.panel-default > .panel-heading + .panel-body`
  -> BS5 `.card > .card-header(h2/h3) + .card-body`. This is the standard
  BL8->BL9 / BS3->BS5 migration; kept the BS5 markup and re-skinned it rather
  than reverting the DOM.
- **Fix (on `#sidebar .card`):** `--bs-card-bg: #fff` (restore white fill) +
  `margin-bottom: 20px` (restore orig inter-card gap).
- **File:** `app/assets/stylesheets/main.scss`.
- **Scope:** `#sidebar .card`. Sidebar appears on document show pages.
- **Note:** header tint still differs slightly (orig `#f5f5f5` headers vs port
  near-white `rgba(0,0,0,.03)`); deferred as a separate follow-up if wanted.

### 8. Fix search bar elements flush (no gap between select/input/buttons)
- **Element:** `.search-bar--header .input-group`, `.search-bar--home .input-group`, `.search-bar--light-bg .input-group`.
- **Problem:** Select, input, keyboard button, and Search button rendered flush with no visible gap. Orig had ~8px gaps between all elements.
- **Cause:** Port3000 had `gap: 0.25em` (~4.75px) on `.input-group`, offset to ~3.75px visual by Bootstrap 5's `margin-left: -1px` applied to non-first `.input-group` children. Orig used `justify-content: space-evenly` on a `.search-input-group` wrapper, yielding ~7.5px gaps.
- **Fix:** Changed `gap: 0.25em` to `gap: 8px` in all three search bar `.input-group` blocks. Also added `> * { margin-left: 0 !important; }` to neutralise BS5's negative margin (which is meant for border-merged input groups; these elements have `border-radius: 4px` and should NOT merge borders).
- **File:** `app/assets/stylesheets/main.scss`.
- **Scope:** COMMON (all three search bars: header, home, light-bg). Do not reapply.

### 7. Fix keyboard dropdown button shorter than Search button
- **Element:** `#dropdownMenuButton` (the keyboard icon button in the search bar).
- **Problem:** The blue Search button appeared taller than the keyboard-icon dropdown button next to it.
- **Cause:** `button#search` has an explicit `height: 40px` rule. `#dropdownMenuButton` had no explicit height, so it rendered at its natural BS5 `.btn` size (~39.125px at 0.8rem/19px base font). The ~0.875px difference, combined with `border-radius: 4px` on `.search-btn`, made the Search button look like a taller floating pill vs the slightly-shorter flat keyboard button.
- **Fix:** Added `height: 40px` to `#dropdownMenuButton` in `app/assets/stylesheets/main.scss` so both buttons match the 40px row height.
- **Scope:** COMMON (all search bars with the keyboard dropdown). Do not reapply.

### 6. Fix Source Sans Pro webfont never loading (system-font fallback)
- **Element:** all body/UI text site-wide (observed on aspie while comparing).
- **Problem:** port rendered in the system sans-serif (heavier letterforms)
  while orig rendered in Source Sans Pro, even though both DECLARE the same
  `font-family: "Source Sans Pro", sans-serif`. The declared family matched;
  the actual webfont was simply never loaded in port.
- **Cause:** `main.scss:1` loaded the font via a CSS `@import`
  (`@import url('https://fonts.googleapis.com/css?family=Source+Sans+Pro...')`).
  The asset pipeline (`require_tree .` in `application.scss`) concatenates every
  stylesheet into ONE `application.css`, so that `@import` ended up at line
  ~15951 of the 19069-line served bundle. CSS only honors `@import` at the very
  TOP of a stylesheet; mid-bundle the browser silently ignores it -> font never
  loads -> system fallback. Orig serves each source file separately, so its
  `main.css` `@import` is at line 1 and works.
- **Fix (2 files):**
  1. `app/views/layouts/application.html.erb` -> added a `<link rel="stylesheet">`
     for the Google Fonts URL (plus `preconnect` hints) in `<head>`, before
     `stylesheet_link_tag 'application'`. A `<link>` loads regardless of bundle
     ordering.
  2. `app/assets/stylesheets/main.scss` -> removed the dead mid-bundle `@import`,
     left a comment explaining the move.
- **Scope:** GLOBAL (application layout + main.scss). Affects every page, not
  just aspie. Found while comparing this page. Do not reapply per-page.
- **Verified:** `<link>` present in rendered port HTML; screenshot letterforms
  now match orig (note: scraper can't inline cross-origin `@font-face` rules, so
  captured `styles.css` still shows 0 `@font-face` -- this is expected and not a
  regression; the browser still loads/applies the font at render time).
