# Splash — STATUS: FINISHED

User signed off. All changes below are accepted.

## Changes

### 1. Restore mlib-styles responsive font-size (COMMON / global)
- **Problem:** Type scale undersized and rem-based containers collapsed
  (`.splash-container`/`.footer-container` at `max-width:60rem` rendered
  840px instead of orig's 1140px).
- **Cause:** `main.scss` forced `html,body { font-size:14px }` plus a
  `@media (min-width:42rem){ font-size:14px !important }` override, fighting
  `mlib-styles.css` which sets 16px base / 19px at >=42rem (what orig uses).
- **Fix:** Removed the override so mlib-styles' responsive sizing applies.
- **File:** `app/assets/stylesheets/main.scss` (html/body block).
- **DOM:** unchanged. **Scope:** GLOBAL/common — affects every page; do not reapply.

### 2. Constrain/center the page container (COMMON / source fix)
- **Problem:** Header logo/title and secondary nav ran flush to the viewport
  edge instead of being centered with a gutter.
- **Declared cause (not computed):** `mlib-styles.css` declares
  `.container--full { max-width: none }`. In orig this was harmless because
  Bootstrap 3 set a *fixed* `.container { width: 1170px }` that still
  constrained the element (the 1170px was a BS3 artifact, never declared on
  `.container--full`). Bootstrap 5 containers use `max-width` only, so
  `max-width: none` removed the constraint entirely -> full-bleed 1280px.
- **Fix (root cause, BS5-idiomatic, no magic px):** changed
  `mlib-styles.css` `.container--full` to `max-width: 60rem` -- the codebase's
  existing responsive container token (same one used by splash/footer). The
  base `.container` already supplies `margin: 0 auto` + `padding: 0 1rem`, so
  the element now centers correctly and collapses cleanly on tablet/mobile.
- **Files:** `app/assets/stylesheets/mlib-styles.css` (`.container--full`);
  `main.scss` header block reduced to just the header-specific padding.
- **DOM:** unchanged. **Scope:** COMMON -- all pages.
- **Divergence from orig (approved):** orig's header is 1170px (a BS3 fixed
  width); we intentionally use the idiomatic responsive `60rem` token instead
  of hardcoding 1170px, so header/hero/fact-panel share one consistent gutter.

### 3. Fix white secondary-nav stripe height (COMMON / header)
- **Problem:** White nav stripe (Dictionary/Bibliography/...) taller than orig.
- **Cause:** Port added `font-size:1.15em` to `ul.header-nav-secondary a`
  (orig has none) -> ~22px links + scaled `.5em` padding inflated the stripe.
- **Fix:** Removed `font-size:1.15em` so links inherit 19px like orig.
- **File:** `app/assets/stylesheets/main.scss`.
- **DOM:** unchanged. **Scope:** COMMON header — applies to all pages.

### 4. Remove gray gap/whitespace under nav (splash-specific)
- **Problem:** Gray strip + whitespace between the white nav and the splash
  banner; orig has none.
- **Cause:** Port wraps content in `<main id="main-content">` (orig has no
  `<main>`). Blacklight's default `main { padding-block: var(--bl-main-padding-y) }`
  (~9.5px) pushed the full-bleed `.splash-banner` down, exposing the gray body
  background (#f2f2f2).
- **DOM difference decision:** `<main id="main-content">` is a valuable a11y
  landmark and skip-link target — KEEP the DOM, fix via CSS.
- **Fix:** Added `.blacklight-catalog-splash #main-content { padding-block:0 }`
  (scoped to splash so other Blacklight catalog pages keep their main padding).
- **File:** `app/assets/stylesheets/main.scss` (near `.splash-banner`).
- **Scope:** splash page only.
