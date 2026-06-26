# ety_french — STATUS: FINISHED

## Summary

No page-specific changes needed. This is a standard search-results page; all
visual parity comes from COMMON search-page fixes already applied for
`a_search` (constraint chip restyle, facet accordion white background, facet
heading separator).

## Reviewed / accepted as-is

- **Remove-constraint "X" icon:** orig used BS3 `glyphicon-remove` (dark green
  rgb(4,78,42)); port uses Blacklight 9 `bi-x-lg` SVG (gray). New-style X
  accepted by user — accessibility/library change, left alone.
- **Search-field select / input group:** minor computed-width deltas
  (BS5 `form-select` padding vs BS3). Within tolerance, renders correctly.

User signed off: whole page is fine.
