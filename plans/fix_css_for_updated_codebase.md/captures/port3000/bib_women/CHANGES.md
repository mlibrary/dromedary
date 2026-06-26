# bib_women — CHANGES

## Search-term constraint chip missing the search-field label

**Problem:** The toolbar query chip showed only the search term (`women`)
instead of the orig's `Entire entry: women`. The search-field label
(`filter-name`, "Entire entry") was absent from the DOM.

**Cause:** The app partial
`app/views/catalog/_query_constraint.html.erb` inlined Blacklight 9's
default-search-field guard:

```erb
label: default_search_field?(params[:search_field]) ? nil
         : label_for_search_field(params[:search_field]),
```

BL9 suppresses the field label whenever the active search field is the
controller's **default**. In `BibliographyController`, `bib_keyword`
("Entire entry") is the first search field and none is flagged
`default: true`, so it becomes the default -> the label was dropped.
(Dictionary chips looked fine because they search a NON-default field
`h`, dodging the guard.) The pre-migration ("orig", BS3-era) site always
showed the label in this chip.

**DOM:** Differs from orig (server-rendered label text). Not a CSS issue —
no stylesheet can inject text the server never emitted. The BL9
behavior change is an unwarranted regression vs. the orig blueprint;
fixed to match.

**Render path note:** The visible toolbar chip is rendered by this app
partial (from `catalog/_sort_and_per_page` and
`bibliography/_sort_and_per_page`), NOT by `Blacklight::ConstraintsComponent`
(whose query chip is CSS-hidden in the sidebar). So the fix belongs in the
partial, not a component override.

**Fix:** `app/views/catalog/_query_constraint.html.erb` — dropped the
default-field guard so the label always renders:

```erb
label: label_for_search_field(params[:search_field]),
```

Result: chip renders `Entire entry > women` (BL9 caret separator,
consistent with the finished dictionary_non-headword chip). Fixes both
catalog and bibliography toolbar chips with one change.

**Status:** Approved by user.
