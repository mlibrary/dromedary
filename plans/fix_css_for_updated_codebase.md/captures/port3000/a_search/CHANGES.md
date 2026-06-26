# a_search — STATUS: FINISHED

## Changes

### 1. Restyle BL9 constraint chip (query pill) — COMMON search results pages

- **Problem:** The "a ×" query constraint chip rendered as a large gray-outlined
  Bootstrap 5 `btn-outline-secondary` pair (19px, gray border, split `a | ×`).
  Orig rendered as a compact white `btn-default btn-sm` chip (12px, `a ×`).
- **Cause:** BL9 changed the constraint component markup from `btn-default btn-sm`
  to `btn-outline-secondary` at the base font size.
- **Fix:** Added `.applied-filter.constraint .btn` override: `font-size: 12px`,
  `padding: 5px 10px`, `background-color: #fff`, `border-color: #ccc`,
  `color: #333`. Matches BL6 `btn-default btn-sm` appearance.
- **File:** `app/assets/stylesheets/main.scss`.
- **Scope:** COMMON — applies to all search results pages with query constraints.

### 2. Restore white background + dark text on facet accordion items — COMMON

- **Problem:** Sidebar facet panels (Part of Speech, Subject Labels, etc.)
  rendered with a gray (`#f2f2f2`) background and muted `#4a4a4a` text.
  Orig showed white panels with dark body text (`rgb(38,38,38)`).
- **Cause:** BS5 accordion uses `--bs-accordion-bg: var(--bs-body-bg)` and
  `--bs-accordion-color: var(--bs-body-color)`. `bootstrap-variables.scss`
  sets `$body-bg: #f2f2f2` and `$body-color: #4a4a4a`, so both bleed into
  every accordion item. Orig BS3 `.panel-default` was explicitly white.
- **Fix:** Added `.accordion-item.facet-limit { --bs-accordion-bg: #fff;
  background-color: #fff; margin-top: 2px; }` and
  `.accordion-body { color: rgb(38,38,38) }` to restore orig panel appearance.
- **File:** `app/assets/stylesheets/main.scss`.
- **Scope:** COMMON — applies to all pages with BL9 facet sidebars.

### 3. Add border-bottom separator under facet heading — COMMON

- **Problem:** No visible separator between the "Part of Speech" heading and
  the facet value list. Orig had a `1px solid #ddd` line.
- **Cause:** BS3 `.panel-heading` inside `.panel-default` got a bottom border
  from the panel's border-color. BS5 accordion button has no such border.
- **Fix:** Added `border-bottom: 1px solid #ddd` to
  `.facet-field-heading .accordion-button`.
- **File:** `app/assets/stylesheets/main.scss`.
- **Scope:** COMMON — applies to all pages with BL9 facet sidebars.
