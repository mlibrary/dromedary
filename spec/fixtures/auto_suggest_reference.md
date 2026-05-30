# Auto-suggest Regression Reference

## Status: Documented at BL6.15.0 baseline (pre-upgrade)

This file is the reference artifact for auto-suggest validation at every Blacklight major
version boundary (6->7, 7->8, 8->9). Any regression in auto-suggest behavior must be
caught at the phase gate before proceeding.

## Endpoint

BL6 suggest path: `GET /dictionary/suggest?q=<term>&search_field=<field_key>`

Example:
```
GET /dictionary/suggest?q=lo&search_field=h
```

## Search fields (from config/autocomplete.yml)

| Field key | solr_endpoint                  | search_component_name          | Description          |
|-----------|-------------------------------|-------------------------------|----------------------|
| `h`       | headword_only_suggester       | headword_only_suggester       | Headword only        |
| `hnf`     | headword_and_forms_suggester  | headword_and_forms_suggester  | Headword + forms     |
| `oed`     | oed_suggester                 | oed_suggester                 | OED suggestions      |

Config: `config/autocomplete.yml`, loaded via `Rails.application.config_for(:autocomplete)`
Assigned in: `app/controllers/catalog_controller.rb` line ~315 via `config.autocomplete`

## Blacklight 6 routing

BL6 registers `suggest` as a collection action on the catalog resource. In the dromedary
routes this is mounted at `/dictionary` (not `/catalog`), so the suggest path is:

```
/dictionary/suggest
```

NOT `/catalog/suggest` (which would be the BL default with default routing).

## Expected response format (BL6)

BL6's suggest controller returns a JSON response from Solr's suggest handler.
The shape is Solr-native:

```json
{
  "responseHeader": { "status": 0, "QTime": 3 },
  "suggest": {
    "headword_only_suggester": {
      "lo": {
        "numFound": 5,
        "suggestions": [
          { "term": "loath", "weight": 0, "payload": "" },
          { "term": "lord", "weight": 0, "payload": "" }
        ]
      }
    }
  }
}
```

## Typeahead JavaScript behavior (BL6)

- Trigger: user types in the `#q` search input on the dictionary page
- Minimum characters: 2 (BL6 default)
- JS component: BL6 ships `blacklight/autofill` (jQuery-based)
- Populates a dropdown below the search box with matching headword suggestions
- Selecting a suggestion fills the `#q` field and submits the search

## Validation checklist (at each BL upgrade gate)

Run these checks manually or via the system spec before marking the gate as passed:

- [ ] `GET /dictionary/suggest?q=lo&search_field=h` returns HTTP 200 with JSON body
- [ ] Response contains `suggest` key with suggestions array
- [ ] Auto-suggest dropdown appears after typing 2+ characters in the dictionary search box
- [ ] Selecting a suggestion populates the search field
- [ ] All three search field variants (`h`, `hnf`, `oed`) return suggestions for their
      respective suggesters when the Solr suggest components are built
- [ ] Suggest endpoint returns HTTP 200 for bibliography and quotations controllers
      (if they have separate suggest configs -- verify in each controller's `blacklight_config`)

## Known history

- BL6.15.0 was pinned with comment: "They messed with the auto-suggest code, so we're
  stuck here for a while."
- The pin was for a behavioral regression in auto-suggest that appeared in BL6.16+
- Decision (upgrade plan pre-work): proceed with upgrades and fix auto-suggest if it
  regresses, rather than staying pinned indefinitely
- Auto-suggest must be explicitly validated at BL6->7, BL7->8, and BL8->9 boundaries

## Indexing_steps.rb suggest rebuild

After indexing, `lib/med_installer/indexing_steps.rb` calls the Solr suggest build endpoint:

```ruby
connection.get "#{url}?suggest.build=true"
```

where `url` is the suggester handler path (e.g. `/solr/med-preview/headword_only_suggester`).
This must succeed for suggestions to be available. Verify as part of the indexing smoke test.
