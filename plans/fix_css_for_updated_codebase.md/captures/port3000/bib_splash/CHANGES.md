# bib_splash — FINISHED

URL: /m/middle-english-dictionary/bibliography

## Change 1: Search-field select full-width (broke form into 2 rows)

- Element: `.search-bar--light-bg select.form-select` ("Entire entry" dropdown)
- Symptom: select computed `width: 492px`, flex-growing to fill, wrapping
  the search input + button onto a second row. Orig was ~165px, content-sized,
  single row.
- Cause: Bootstrap 5 `.form-select` forces `width: 100%`; inside the
  `.input-group` flex container it grew. BS3 sized the select to content via an
  `.input-group-addon` wrapper.
- DOM diff: orig wrapped the select in `.input-group-addon` (BS3); port uses a
  bare `.form-select` (BS5). Kept the BS5 DOM (idiomatic), fixed via CSS only.
- Fix (`app/assets/stylesheets/main.scss`, `.search-bar--light-bg select.form-select`):
  added `flex: 0 0 auto; align-self: stretch; width: auto;`, indicator-clearance
  padding, and `font-size: 16px; line-height: 1.2` to match orig. Mirrors the
  existing fix in `.search-bar--header`.

## Change 2: Remove "Advanced search" link

- Element: `a.advanced_search` rendered below the search bar.
- Symptom: port3000 showed an "Advanced search" link absent in orig.
- Cause: Blacklight 9 enables advanced search by default. `CatalogController`
  already disabled it, but `BibliographyController` did not.
- Fix (`app/controllers/bibliography_controller.rb`): added
  `config.advanced_search.enabled = false` in the `configure_blacklight` block,
  matching `CatalogController`.
