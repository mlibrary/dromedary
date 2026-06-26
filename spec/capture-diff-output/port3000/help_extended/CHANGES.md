# help_extended — Capture-Diff Changes

> **STATUS: FINISHED** — signed off by user. No further changes needed.

## Change 1: Restyle the table caption

- **Element:** `table caption` ("Middle English Compendium search examples").
- **Symptom:** port3000 caption sat at the table BOTTOM (BS5 default
  `caption-side: bottom`; BS3 was top) and was styled as dark, full-size
  body text — looked like a stray sentence rather than a caption. Orig
  rendered it muted gray at the top.
- **User decision:** Bottom placement is fine; just style it better.
- **Root cause:**
  - BS5 sets `caption-side: bottom` by default (BS3 defaulted to top).
  - The SCSS rule `caption { color: #212B36; }` (main.scss:1814) forced a
    dark color, discarding the muted gray look.
  - A global CSS reset (mlib-styles) sets `caption { font-size: inherit;
    font-style: inherit; }` and loads AFTER main.scss, so any
    `font-size`/`font-style` on a bare `caption {}` selector (specificity
    0,0,1) gets overridden. Scoping to `table caption` (0,0,2) is required
    to win.
- **Fix (`app/assets/stylesheets/main.scss`):**
  ```scss
  caption {
    color: #777;
  }

  table caption {
    color: #777;
    padding-top: 0.75em;
    font-size: 0.85em;
    font-style: italic;
    text-align: left;
  }
  ```
  Muted gray (`#777`, matching orig's `rgb(119,119,119)`), slightly smaller
  (0.85em), italic, with top spacing to separate it from the table — reads
  as a proper caption while staying at the bottom.

## Notes / shared impact

- The `caption {}` selector is global, but `table caption` only affects
  captions inside real tables. Restyle is intentional and tasteful across
  any data table site-wide.
- The layout (two-column sidebar + content) on this page was already correct
  via the shared `div.help-container` / `.help-sbar` rules — no layout change
  needed here.
