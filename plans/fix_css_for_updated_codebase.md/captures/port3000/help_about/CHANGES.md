# help_about — Capture-Diff Changes

> **STATUS: FINISHED** — signed off by user. No further changes needed.

## Change 1: Use the help-page DOM so two-column layout + gutter apply

- **Symptom:** port3000 stacked the columns vertically (sidebar on top,
  content below); orig (`:3001`) shows them side-by-side like the other help
  pages.
- **Root cause:** The about page did NOT share the help-page layout DOM:
  - `about_med.html.erb` wrapped content in `<div class="container">` —
    MISSING the `help-container` class.
  - `_about_sidebar.html.erb` used `about-sbar`, which has ZERO CSS.
  So neither the BS5 flex-row fix (`div.help-container > div { display:flex }`)
  nor the gutter rule (`.help-sbar { padding-right:1.5em }`) — both added when
  fixing `help_using` — could apply. Under BS5 the `.col-*` columns (no longer
  floated) rendered as stacked block elements.
- **DOM verdict:** Orig DOM is the broken one too; the right fix is to make
  help_about reuse the existing help-page structure rather than add bespoke
  CSS.
- **Fix (DOM only, no new CSS):**
  - `app/views/static/about_med.html.erb`:
    `<div class="container">` → `<div class="container help-container">`
  - `app/views/static/_about_sidebar.html.erb`:
    `class="<%= sidebar_classes %> about-sbar"` →
    `class="<%= sidebar_classes %> help-sbar"`
- **Why safe:** `about-sbar` carried no styles, so switching to `help-sbar`
  loses nothing and gains the shared two-column + gutter behavior. The
  about-specific sidebar content (`<h2>` heading + in-page anchor links) is
  preserved.

## Notes / shared impact

- This reuses the rules added for `help_using`
  (`div.help-container > div` flex row + `.help-sbar` gutter in
  `app/assets/stylesheets/main.scss`). No stylesheet change was needed here —
  purely a DOM alignment so help_about matches the rest of the help pages.
