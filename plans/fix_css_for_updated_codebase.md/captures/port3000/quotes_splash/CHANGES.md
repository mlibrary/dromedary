# quotes_splash — Capture-Diff Changes

> **STATUS: FINISHED** — signed off by user. No further changes needed.

## Change 1: Restore gray border on search input box

- **Element:** `.search-bar--light-bg .search-autocomplete-wrapper.form-control`
  (the "Search..." text input box inside the light-bg search panel).
- **Symptom:** port3000 search input had no gray outline; orig shows a
  `1px solid #ccc` bordered box.
- **Root cause:** DOM changed from BS3 twitter-typeahead
  (`<span class="twitter-typeahead"> + <input class="form-control">`) to a
  BS5 `<auto-complete>` web component (`.search-autocomplete-wrapper`). As a
  direct `.input-group` child, the global rule at `main.scss:453`
  (`.input-group > .search-autocomplete-wrapper.form-control`) strips its
  border with `border: medium !important`, and the light-bg variant rule set
  `border: none`. Net result: a borderless input.
- **DOM verdict:** The DOM change is warranted (new autocomplete JS library
  replacing twitter-typeahead). Kept the new DOM; restored styling via CSS.
- **Fix:** In `app/assets/stylesheets/main.scss`, inside
  `.search-bar--light-bg .search-autocomplete-wrapper.form-control`, changed
  `border: none;` to:
  ```scss
  border: 1px solid #ccc !important;
  border-radius: 4px;
  ```
  `!important` is required to override the global `border: medium !important`
  rule at `main.scss:453`. Matches orig's input border
  (`1px solid rgb(204, 204, 204)`).
- **Status:** Accepted / signed off by user.
