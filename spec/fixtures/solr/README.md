# Solr integration fixture

`MED_A_SMALL_SANITIZED.zip` is the integration-test dataset.
It preserves 131 MED records, XML structure, identifiers, headwords, senses,
parts of speech, citations, quote counts, and bibliography records.
Non-whitespace text under `<DEF>` and `<Q>` becomes
`Lorem ipsum dolor sit amet.` Bibliography and link files remain unchanged.

The RSpec bootstrap indexes this archive into the `med-spec` Solr alias
when required records or placeholder text are missing. It never repoints
`med-preview`.

Run locally with:
`docker compose exec -e RUN_INTEGRATION=1 app bundle exec rspec --tag integration`.
