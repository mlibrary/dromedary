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

### 2. Center the header container (COMMON / header)
- **Problem:** Header logo/title and secondary nav ran flush to the viewport
  edge instead of orig's ~55px gutter.
- **Cause:** `.container--full { max-width:none }` removed orig's centered
  1170px Bootstrap container.
- **Fix:** Added `max-width:1170px; margin:0 auto` to
  `.container.container--full.site-header-container`.
- **File:** `app/assets/stylesheets/main.scss`.
- **DOM:** unchanged. **Scope:** COMMON header — applies to all pages.
- **Note:** Header container is 1170px (55px gutter) while splash/footer are
  60rem=1140px (70px gutter); this mismatch matches orig exactly.

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
