# help_using — Capture-Diff Changes

> **STATUS: FINISHED** — signed off by user. No further changes needed.

## Change 1: Restore two-column layout (sidebar + content)

- **Element:** `div.help-container > div` (wrapper holding the `.help-sbar`
  sidebar column and `.about-middle-col` content column).
- **Symptom:** port3000 stacked the columns vertically; orig shows them
  side-by-side (narrow TOC sidebar left, white content card right).
- **Root cause:** BS3 laid grid columns out via `float: left`. BS5 dropped
  column floats — `.col-*` only flow horizontally inside a flex `.row`. The
  help view nests both columns in a plain class-less `<div>` (the real
  `.row` is higher up, wrapping the `.container`), so under BS5 the columns
  rendered as stacked block elements.
- **DOM verdict:** Orig DOM is identical (same plain wrapper). Kept the DOM;
  fixed in CSS rather than adding a `.row` class.
- **Fix (`app/assets/stylesheets/main.scss`, `div.help-container`):**
  ```scss
  > div {
    display: flex;
    flex-wrap: wrap;
  }
  ```
  `flex-wrap` preserves responsive stacking (mobile `col-12` → 100% wraps).

## Change 2: Gutter between the two columns

- **Element:** `.help-sbar` (the sidebar grid column).
- **Symptom:** after Change 1 the gray sidebar box sat flush against the
  white content card; orig has a visible page-colored gutter between them.
- **Why applied on the sidebar side:** `.about-middle-col` is itself the
  white card (its background fills the whole column), so left padding/margin
  there would show as white, not a gap. The gutter must come from the
  sidebar column's right edge.
- **Fix (`app/assets/stylesheets/main.scss`, `div.help-container`):**
  ```scss
  .help-sbar {
    padding-right: 1.5em;
  }
  ```
  `border-box` keeps the column at 25% width (no flex wrap); the gray
  `.sidebars` box shrinks, opening the gutter to the content card.

## Notes / shared impact

- The `div.help-container > div` wrapper structure is shared by ALL help
  pages (`help/dictionary`, `help/bibliography`, `help/quotations`,
  `help/special_characters`, `help/extended`, plus `help_general`,
  `help_med`, etc.), so both rules fix the column layout across every help
  page in one place. Do not reapply per-page.
