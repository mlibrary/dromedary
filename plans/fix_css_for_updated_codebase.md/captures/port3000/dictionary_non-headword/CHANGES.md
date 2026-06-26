# dictionary_non-headword — CHANGES

> **FINISHED** — all changes accepted by user. No further work needed.

## Sidebar accordion entry padding

**Problem:** Facet entries in the sidebar accordions (Part of Speech,
Source Language) had too much vertical padding around each row.

**Cause:** BL9 adds `--bl-facet-value-padding-y: 0.2rem` and applies it as
`padding-block` on each `.facet-values li` (computed ~4.75px top/bottom).
Orig rendered facet rows with the `display: table`/`table-row` model and
**zero** vertical padding (the declared `padding-bottom: 9px` on
`.facet-label` was dead CSS, overridden to `0` later in orig's stylesheet;
confirmed via computed `padding: 0px 19px 0px 0px`).

**DOM:** Differs (orig table model -> BL9 flex `li`). Warranted BL9
modernization; kept the DOM, overrode the spacing only.

**Fix:** `app/assets/stylesheets/main.scss` — override BL9's per-entry
padding to match orig's tight rows:

```scss
.facet-values li {
  --bl-facet-value-padding-y: 0;
  padding-block: 0;
}
```

Result: facet `li` now `height: 28px` (line box only), no vertical padding.

**Status:** Approved by user.

## Chip separator chevron (search-type -> term)

**Problem:** In the applied-filter chip ("Headword (preferred spelling
only) > abacus"), the separator between the search type and the search
term rendered as an oversized, thin, light bootstrap-icons chevron with
excessive whitespace. Orig showed a small, solid, tight caret.

**Cause:** Bootstrap 5 dropped the Glyphicons font that orig (BS3) used for
this separator. BL9 replaced it with a bootstrap-icons chevron-right SVG
*mask* on `.applied-filter .constraint-value .filter-name::after`, sized at
`height:1.1rem; width:1.25rem` with wide margins and no `mask-size` -> the
16px intrinsic SVG only got clipped, appearing large and thin-stroked.

**DOM:** Differs from orig (Glyphicons font glyph -> bootstrap-icons SVG
mask; `filterName`/`filterValue` -> `filter-name`/`filter-value`). This is a
warranted BL9 modernization. Kept the DOM; restyled the pseudo-element only.

**Fix:** `app/assets/stylesheets/main.scss` — neutralized BL9's SVG mask on
`.search-term-filter .applied-filter .constraint-value .filter-name::after`
(`background:none; mask-image:none`) and replaced it with the same small
solid right-caret used by the facet accordion headings
(`.facet-field-heading .accordion-button.collapsed::after`): a CSS border
triangle, `#4A4A4A`, no webfont required.

```scss
.search-term-filter .applied-filter .constraint-value .filter-name::after {
  content: "";
  width: 0;
  height: 0;
  background: none;
  mask-image: none;
  -webkit-mask-image: none;
  border-top: 4px solid transparent;
  border-bottom: 4px solid transparent;
  border-left: 5px solid #4A4A4A;
  margin-left: 6px;
  margin-right: 6px;
  vertical-align: middle;
  transition: none;
}
```

**Status:** Approved by user.
