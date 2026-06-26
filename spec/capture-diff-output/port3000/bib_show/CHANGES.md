# bib_show CHANGES

> **FINISHED** - This page is signed off and complete.


## Entry Info table zebra striping

**Element:** `.entry-info table` (class `table table-striped bib-table`) rows.

**Bug:** port3000 rendered all table rows a uniform gray (`#f2f2f2`). Orig
alternates `#f9f9f9` (odd) / `#f2f2f2` (even) zebra striping.

**Why:** Bootstrap 3 -> 5 migration. BS5 stripes cells via `box-shadow` plus
`--bs-table-bg` (which resolves to the body bg `#f2f2f2`). The default
`--bs-table-striped-bg` is a darker 5%-black accent, and a blanket
`.entry-info tr { background-color: #f2f2f2 }` override flattened every row, so
no visible alternation remained.

**DOM:** Identical between variants. No DOM change needed.

**Fix (BS5-idiomatic):** In `app/assets/stylesheets/main.scss`, set table CSS
variables on `.entry-info table, .entry-supplement table`:

```scss
--bs-table-bg: #f2f2f2;        // even rows
--bs-table-striped-bg: #f9f9f9; // odd rows (lighter stripe)
--bs-table-striped-color: inherit;
```

Removed the blanket `.entry-info tr, .entry-supplement tr { background-color: #f2f2f2 }`
override (now handled by the table variables).

**Status:** Accepted by user.
