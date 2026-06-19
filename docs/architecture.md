# Dromedary Architecture Reference

> Generated for agentic consumption. Designed so a consuming agent can understand
> the full system without opening most source files.

---

## 1. What Is This?

Dromedary is the **Middle English Dictionary (MED)** web application, built on
Ruby on Rails + Blacklight + Apache Solr. It provides three public search
interfaces (dictionary entries, bibliography, quotations) and an admin interface
for managing data uploads and Solr collection promotion.

---

## 2. Repository Layout

```
dromedary/
  app/
    controllers/        # Rails controllers (catalog, bibliography, quotes, admin)
    controllers/concerns/dromedary/catalog.rb  # shared Blacklight concern
    jobs/               # Sidekiq jobs (IndexDataJob)
    mailers/
    models/             # SolrDocument, SearchBuilder, MedSolrCollection(s)
    presenters/         # Blacklight presenter overrides
      dromedary/
        index_presenter.rb          # entry (dictionary) search results
        bib/index_presenter.rb      # bibliography search results
        quotes/index_presenter.rb   # quotations search results
      common_presenters.rb          # shared hl_field / first_found_value helpers
  config/
    application.rb      # Rails app init, JSON log formatter
    blacklight.yml      # (mostly commented out; Solr URL comes from Services)
    autocomplete.yml    # maps search field name -> Solr suggest handler + component
    database.yml        # PostgreSQL; host=db, user/pass=postgres
    sidekiq.yml         # Sidekiq queue config
    routes.rb           # all HTTP routing
    load_local_config.rb  # loads local-override config files
    settings/
      production.yml    # (currently empty; ENV is authoritative)
      development.yml
      test.yml
    initializers/
      okcomputer.rb     # OkComputer.mount_at = false (health at /status)
      explicit_proxy_host.rb  # Rack middleware: injects X-Forwarded-Host from ENV
      routes_proxy_script_name_fix.rb  # fixes Rails 5.2 script_name bug
      autocomplete_override_code.rb   # overrides BL9 autocomplete endpoint
      ... (standard Rails initializers)
  indexer/
    main_indexing_rules.rb     # Traject rules for MED entries
    bib_indexing_rules.rb      # Traject rules for bibliography
    quote/
      quote_indexer.rb         # runs quote indexing (called from main rules)
    writers/
      containerized_solr_writer.rb  # Traject writer: writes to a named Solr collection
      localhost.rb                  # Traject writer: targets local Solr (legacy)
      debug.rb                      # Traject writer: logs records to file
      json.rb
  lib/
    annoying_utilities.rb       # path helpers, config-file loader, solr_core builder
    dromedary/
      services.rb               # Canister DI container (THE config hub)
      smart_xml.rb
      xslt_utils.rb
    med_installer/
      extract.rb                # STEP 1 of prepare: unzip Box zip into xml/
      convert.rb                # STEP 2 of prepare: XML -> entries.json.gz
      prepare.rb                # CLI: runs extract + convert
      index.rb                  # CLI: Traject-based indexing commands
      extract_convert_index.rb  # Legacy all-in-one pipeline (may be broken)
      index_new_data.rb         # Current split pipeline: create collection + index
      indexing_steps.rb         # Step sequencer used by index_new_data
      copy_from_build.rb        # CLI: copies build files to live data dir
      hyp_to_bibid.rb           # builds/reads HYP-id -> BIB-id mapping
      control.rb                # maintenance mode on/off
      solr.rb                   # Solr admin CLI commands (commit, optimize, etc.)
      job_monitoring.rb         # pushes metrics to Prometheus Pushgateway
      remote.rb                 # remote exec helpers
      logger.rb                 # SemanticLogger mixin
    serialization/
      indexable_quote.rb        # quote serialization for indexing
    my_simple_solr_client.rb    # thin Solr client wrapper
  solr/
    dromedary/conf/             # Solr configset (schema.xml, solrconfig.xml, etc.)
    Dockerfile                  # Solr image (solr:10 + ICU + basic auth)
  kubernetes/
    remote-k8s/                 # production K8s manifests
    base-k8s/                   # shared service definitions
    local-k8s/                  # local K8s
    pvc-k8s/                    # persistent volume claims
  compose.yml                   # docker-compose for local dev
  Gemfile
  Rakefile
```

---

## 3. The Service Container (THE Config Hub)

**File:** `lib/dromedary/services.rb`

All application-wide configuration lives in `Dromedary::Services`, a
`Canister`-backed lazy DI container. Every registered value is a lambda
evaluated on first access. Controllers, models, indexing code, and CLI tools
all read from `Dromedary::Services[:key]` — **never raw ENV directly** (ENV is
read inside the lambdas).

### Key Services

| Key | Source / Default | Description |
|-----|-----------------|-------------|
| `:root_directory` | `Pathname(__dir__).parent.parent` | App root Pathname |
| `:tmp_dir` | `root_directory + "tmp"` | Temp dir (mkdir if absent) |
| `:rails_url_host` | `ENV["RAILS_URL_HOST"]` | Explicit hostname for URL helpers |
| `:rails_url_protocol` | `ENV["RAILS_URL_PROTOCOL"]` | Protocol for URL helpers |
| `:relative_url_root` | `ENV["RAILS_RELATIVE_URL_ROOT"]` \| `"/"` | Rack SCRIPT_NAME prefix |
| `:production_alias` | `ENV["SOLR_PRODUCTION_ALIAS"]` \| `"med-production"` | Solr alias name for production |
| `:preview_alias` | `ENV["SOLR_PREVIEW_ALIAS"]` \| `"med-preview"` | Solr alias name for preview |
| `:allow_admin_access` | `ENV["ALLOW_ADMIN_ACCESS"]` in `["1","true","TRUE"]` | Enables admin UI |
| `:looks_like_first_upload` | derived | True when admin enabled and no collection exists yet |
| `:solr_root` | `ENV["SOLR_ROOT"]` \| `"http://solr:8983/"` | Base URL of Solr cluster |
| `:solr_collection_base` | `ENV["SOLR_COLLECTION_BASE"]` \| `"med"` | Prefix for collection names |
| `:solr_collection` | `ENV["SOLR_COLLECTION"]` | The active collection (or alias) |
| `:solr_username` | `ENV["SOLR_USERNAME"]` | Solr basic-auth user |
| `:solr_password` | `ENV["SOLR_PASSWORD"]` | Solr basic-auth password |
| `:solr_replication_factor` | `ENV["SOLR_REPLICATION_FACTOR"]` | Replicas for new collections |
| `:solr_connection` | `SolrCloud::Connection.new(...)` | SolrCloud client |
| `:solr_current_collection` | derived from connection + `:solr_collection` | Active collection object |
| `:solr_url` | `solr_root + "/solr/" + solr_collection` | Full URL to current collection |
| `:solr_embedded_auth_url` | solr_url with credentials embedded | URL for tools needing embedded auth |
| `:build_root` | `ENV["BUILD_ROOT"]` | Root of all build directories |
| `:build_date_suffix` | `Time.now.strftime("%Y%m%d%H%M")` | Timestamp suffix for collection names |
| `:build_directory` | `ENV["BUILD_DIRECTORY"]` \| `build_root + "build_<timestamp>"` | Working dir for current indexing run |
| `:build_xml_directory` | `build_directory + "xml"` | XML files extracted from zip |
| `:bib_all_xml_file` | `build_xml_directory + "bib_all.xml"` | Bibliography XML |
| `:entries_gz_file` | `build_directory + "entries.json.gz"` | Converted entries for Traject |
| `:hyp_to_bibid_file` | `build_directory + "hyp_to_bibid.json"` | HYP ID -> BIB ID mapping |
| `:entry_indexing_rules` | `indexer/main_indexing_rules.rb` | Traject rules path |
| `:bib_indexing_rules` | `indexer/bib_indexing_rules.rb` | Traject bib rules path |
| `:solr_writer` | `indexer/writers/containerized_solr_writer.rb` | Traject writer config path |
| `:name_of_solr_collection_to_index_into` | `"<base>_<timestamp>"` | New collection name for indexing run |
| `:solr_collection_to_index_into` | derived | The new `SolrCloud::Collection` object |
| `:solr_conf_directory` | `ENV["SOLR_CONF_DIRECTORY"]` \| `solr/dromedary/conf` | Solr configset dir to upload |
| `:direct_urls_to_solr_replicas` | `ENV["DIRECT_URLS_TO_SOLR_REPLICAS"]` | Space-separated replica URLs for manual suggester builds |
| `:manually_build_suggesters` | `ENV["MANUALLY_BUILD_SUGGESTERS"]` | Boolean; build suggesters on each replica |
| `:aws_bucket` | `ENV["AWS_BUCKET"]` | S3 bucket for Shrine uploads |
| `:aws_region` | `ENV["AWS_REGION"]` | AWS region |
| `:aws_access_key_id` | `ENV["AWS_ACCESS_KEY_ID"]` | AWS key |
| `:aws_secret_access_key` | `ENV["AWS_SECRET_ACCESS_KEY"]` | AWS secret |
| `:shrine_incoming_storage` | derived from AWS keys | Shrine::Storage::S3 config |
| `:logger` | `SemanticLogger` or Rails logger | App-wide logger |

> **Note:** When `AWS_BUCKET` is present, `Shrine.storages` is set and
> presign/multipart upload endpoints become active at `/s3/params` and
> `/s3/multipart`.

---

## 4. Environment Variables Reference

All env vars are read inside `Services` lambdas (lazy). Defaults are shown.

| Variable | Default | Effect |
|----------|---------|--------|
| `SOLR_ROOT` | `http://solr:8983/` | Solr cluster base URL |
| `SOLR_COLLECTION` | (none) | Active collection or alias name |
| `SOLR_COLLECTION_BASE` | `med` | Prefix for new collection names |
| `SOLR_USERNAME` | (none) | Basic auth user |
| `SOLR_PASSWORD` | (none) | Basic auth password |
| `SOLR_REPLICATION_FACTOR` | `1` | Replicas when creating collections |
| `SOLR_PRODUCTION_ALIAS` | `med-production` | Production alias name in Solr |
| `SOLR_PREVIEW_ALIAS` | `med-preview` | Preview alias name in Solr |
| `SOLR_CONF_DIRECTORY` | `solr/dromedary/conf` | Configset to upload |
| `ALLOW_ADMIN_ACCESS` | `false` | Enables admin routes |
| `RAILS_URL_HOST` | (none) | Injected as X-Forwarded-Host by middleware |
| `RAILS_URL_PROTOCOL` | (none) | Protocol for URL helpers |
| `RAILS_RELATIVE_URL_ROOT` | `/` | Rack SCRIPT_NAME (e.g., `/m/middle-english-dictionary`) |
| `BUILD_ROOT` | (none; required for indexing) | Parent of per-run build directories |
| `BUILD_DIRECTORY` | `BUILD_ROOT/build_<timestamp>` | Override specific build dir |
| `DATA_ROOT` | (none) | Root data directory (used in compose) |
| `DIRECT_URLS_TO_SOLR_REPLICAS` | (none) | Space-separated replica URLs for manual suggester builds |
| `MANUALLY_BUILD_SUGGESTERS` | (none) | Force per-replica suggester build |
| `AWS_BUCKET` | (none) | Activates Shrine S3 upload feature |
| `AWS_REGION` | (none) | AWS region for S3 |
| `AWS_ACCESS_KEY_ID` | (none) | AWS key |
| `AWS_SECRET_ACCESS_KEY` | (none) | AWS secret |
| `REDIS_URL` | (none) | Redis for Sidekiq |
| `PROMETHEUS_PUSH_GATEWAY` | (none) | Metrics push target |
| `RAILS_ENV` | `development` | Standard Rails environment |
| `SECRET_KEY_BASE` | (placeholder in Dockerfile) | Rails secret key |

---

## 5. HTTP Routing

**File:** `config/routes.rb`

The URL structure is:

| Path | Controller#Action | Notes |
|------|------------------|-------|
| `/` | `catalog#splash` | Landing page |
| `/dictionary/` (no query) | `catalog#home` | Dictionary splash |
| `/dictionary/:id` | `catalog#show` | Single entry; ID format `MED[\w-.]+` |
| `/dictionary/` (search) | `catalog#index` | Search results via Blacklight |
| `/bibliography/` (no query) | `bibliography#home` | Bib splash |
| `/bibliography/:id` | `bibliography#show` | Single bib; ID format `BIB\|HYP...` |
| `/bibliography/` (search) | `bibliography#index` | Bib search |
| `/quotations/` (no query) | `quotes#home` | Quotes splash |
| `/quotations/` (search) | `quotes#index` | Quotes search |
| `/search` | `catalog#search` | General search redirect |
| `/status` | OkComputer engine | Health checks |
| `/admin` | `admin#home` | Collection management (requires `ALLOW_ADMIN_ACCESS`) |
| `/admin/upload` | `admin#upload` | Upload zip for indexing |
| `/admin/release` | `admin#release` | Promote preview -> production |
| `/admin/force_release` | `admin#force_release` | Force-promote any collection |
| `/admin/delete` | `admin#delete` | Delete a collection |
| `/s3/params` | Shrine presign | S3 direct-upload presign (when AWS configured) |
| `/s3/multipart` | Shrine uppy | S3 multipart upload |

Maintenance mode: when `tmp/MAINTENANCE_MODE_ENABLED` exists, all requests
match `"*path" => "static#maintenance_mode"`.

URL prefix (`RAILS_RELATIVE_URL_ROOT`) is applied at the Rack level, not in
routes. The `ExplicitProxyHost` middleware injects `X-Forwarded-Host` from
`RAILS_URL_HOST` if set.

---

## 6. Controller Architecture

All three search controllers share the same structure:

```
ApplicationController < ActionController::Base
  include Blacklight::Controller
  before_action :store_request_in_thread

  CatalogController < ApplicationController
    include Blacklight::Catalog
    include Dromedary::Catalog          # adds #index, #search, #bib, #home
    configure_blacklight { ... }        # field/facet/sort config
    # custom #suggest override for per-field autocomplete

  BibliographyController < ApplicationController
    include Blacklight::Catalog
    include Dromedary::Catalog
    configure_blacklight { ... }
    # custom #show: HYP ID -> BIB ID redirect

  QuotesController < ApplicationController
    include Blacklight::Catalog
    include Dromedary::Catalog
    configure_blacklight { ... }
```

**`Dromedary::Catalog` concern** (`app/controllers/concerns/dromedary/catalog.rb`):
Overrides Blacklight's `#index` to set `@document_list`; provides empty
`#search`, `#bib` actions; `#home` renders with `layout: "home"`.

### Blacklight Config Per Controller

| Setting | CatalogController | BibliographyController | QuotesController |
|---------|------------------|----------------------|-----------------|
| Solr search handler | `search` | `bibsearch` | `quotesearch` |
| Solr document handler | `document` | `bibdoc` | (default) |
| Default rows | 20 | 100 | 100 |
| Presenter class | `Dromedary::IndexPresenter` | `Dromedary::Bib::IndexPresenter` | `Dromedary::Quotes::IndexPresenter` |
| Key search fields | headword_only, headword_and_forms, oed, definition | bib_keyword, bib_author_title, bib_external_references | quote_everything, quote_quote |
| Facets | discipline, part-of-speech, etymology language | lalme_expansion, laeme_expansion | (none shown) |
| Sort options | Relevance, Alphabetical (sequence asc) | Relevance | Relevance, date/author |

`SearchBuilder` (`app/models/search_builder.rb`) is intentionally **not wired
in** (commented out). The default Blacklight SearchBuilder runs for all queries.

---

## 7. Autocomplete

**Config:** `config/autocomplete.yml`

Maps search field names to Solr suggest endpoints:

```yaml
default: &default
  h:
    solr_endpoint:         headword_only_suggester
    search_component_name: headword_only_suggester
  hnf:
    solr_endpoint:         headword_and_forms_suggester
    search_component_name: headword_and_forms_suggester
  oed:
    solr_endpoint:         oed_suggester
    search_component_name: oed_suggester
```

**Flow:** `CatalogController#suggest` reads `params[:search_field]`, looks up
the handler from `blacklight_config.autocomplete`, calls Solr's suggest
endpoint, then does a secondary Solr `search` call to resolve headword terms
to document IDs (for direct-link `<li>` elements). Returns HTML `<li>`
fragments for Blacklight 9's `<auto-complete>` web component.

---

## 8. Solr Data Model

### Collections and Aliases

Dromedary uses SolrCloud with a blue/green alias promotion strategy:

- Collections are named `<SOLR_COLLECTION_BASE>_<YYYYMMDDhhmm>` (e.g., `med_202409171045`).
- Two aliases exist: `med-production` and `med-preview`.
- The Rails app always reads from `SOLR_COLLECTION` (set to `med-production` in
  production, `med-preview` in compose dev).
- Admin UI promotes preview -> production by re-pointing the `med-production` alias.

**`MedSolrCollection`** (`app/models/med_solr_collection.rb`): wraps a
`SolrCloud::Collection` via `SimpleDelegator`, adds `#preview?`, `#production?`,
`#age_in_minutes`, `#failure?` (0 docs after 80 min = failed), expected
completion time helpers.

**`MedSolrCollections`** (`app/models/med_solr_collections.rb`): enumerates
all collections matching `NAME_MATCHER`, wraps them as `MedSolrCollection`,
exposes `#preview`, `#production`, `#force_release_candidates`, `#set_keepers!`
(marks which collections are safe to delete).

### SolrDocument

`app/models/solr_document.rb`: minimal — includes `Blacklight::Solr::Document`
and `Blacklight::Document::DublinCore`. Field access is through Blacklight's
presenter layer, not direct model methods.

### Solr Request Handlers (in solrconfig.xml)

| Handler | Used By | Purpose |
|---------|---------|---------|
| `/search` | CatalogController | Main MED entry search |
| `/document` | CatalogController | Single entry fetch |
| `/bibsearch` | BibliographyController | Bibliography search |
| `/bibdoc` | BibliographyController | Single bib fetch |
| `/quotesearch` | QuotesController | Quotation search |
| `headword_only_suggester` | autocomplete | Headword-only suggest |
| `headword_and_forms_suggester` | autocomplete | Headword + forms suggest |
| `oed_suggester` | autocomplete | OED cross-reference suggest |

---

## 9. Data Ingestion Pipeline

Source data arrives as a **zip file** (downloaded from Box/CIFS share) containing
per-letter MED XML files, a bibliography XML (`bib_all.xml`), link files, and DTDs.

### Two Pipelines

#### A. Modern Split Pipeline (current)

```
bin/dromedary prepare <zipfile>         # runs Extract + Convert
  -> lib/med_installer/extract.rb       # STEP 1: unzip into build_directory/xml/
  -> lib/med_installer/convert.rb       # STEP 2: XML -> entries.json.gz + hyp_to_bibid.json

bin/dromedary index new_data            # runs IndexNewData
  -> lib/med_installer/index_new_data.rb
     1. create configset + collection in Solr (name: <base>_<timestamp>)
     2. index entries: Traject(main_indexing_rules.rb, entries.json.gz) -> new collection
     3. index bibs: Traject(bib_indexing_rules.rb, bib_all.xml) -> new collection
     4. rebuild suggesters (optionally on each replica individually)
     5. point med-preview alias at new collection

Admin UI: release (promote preview -> production)
```

#### B. Legacy All-in-one (`ExtractConvertIndex`)

`lib/med_installer/extract_convert_index.rb` — combines all steps plus
maintenance mode toggle. **May be broken** (incorrect keyword args).

### Traject Indexing Details

**Entry indexing** (`indexer/main_indexing_rules.rb`):
- Reader: `MedInstaller::Traject::EntryJsonReader` (reads `entries.json.gz`)
- Batch size: 250 docs/commit, log every 2500
- Auth: `solr_writer.basic_auth_user/password` from `Services[:solr_username/password]`
- Key fields indexed: headword, forms, prefixes/suffixes, dubious flag, etymology,
  part-of-speech, definitions, modern equivalents, citations, quotes (via
  `quote_indexer.rb`), author.title, RIDs, manuscripts
- Also runs `quote/quote_indexer.rb` to index quote documents separately

**Bib indexing** (`indexer/bib_indexing_rules.rb`):
- Reader: `MedInstaller::Traject::BibReader` (reads `bib_all.xml`)
- Fields: title, author, title_sort (leading articles stripped), external
  references, LALME/LAEME region, manuscripts

**Traject writer** (`indexer/writers/containerized_solr_writer.rb`):
Writes to `Services[:solr_url]` (the new collection URL, set at indexing time).

### Intermediate Files

| File | Location | Contents |
|------|----------|----------|
| `entries.json.gz` | `build_directory/` | One JSON line per MED entry (gzipped) |
| `bib_all.xml` | `build_directory/xml/` | Full bibliography XML |
| `hyp_to_bibid.json` | `build_directory/` | `{HYP_ID: BIB_ID}` mapping |

`hyp_to_bibid.json` is also uploaded to Solr at index time and fetched at
app startup via `MedInstaller::HypToBibId.get_from_solr(...)` for use in
`BibliographyController#show` redirects.

---

## 10. Admin Interface

**File:** `app/controllers/admin_controller.rb`

Gated by `ALLOW_ADMIN_ACCESS=1` (checked in routes).

Actions:
- `home`: shows all collections, their aliases, document counts, age
- `release`: promotes `med-preview` to `med-production` (deletes old alias, creates new)
- `force_release`: re-points both preview AND production aliases to an arbitrary collection
- `delete`: deletes a collection and its configset (only if `do_not_delete == false`)

**Shrine S3 upload** (when `AWS_BUCKET` set):
- Routes `/s3/params` and `/s3/multipart` for direct browser-to-S3 upload
- After upload completes, `IndexDataJob` (Sidekiq) runs `bin/dromedary extract_convert_index <filename>`

---

## 11. Background Jobs

**Sidekiq** backed by Redis (`REDIS_URL`).

| Job | File | Trigger | Action |
|-----|------|---------|--------|
| `IndexDataJob` | `app/jobs/index_data_job.rb` | Upload complete (admin) | Shells out to `bin/dromedary extract_convert_index <filename>` |
| `PokeSidekiqJob` | `app/jobs/poke_sidekiq_job.rb` | (cron or manual) | Keep-alive / health probe |

K8s CronJob (`kubernetes/remote-k8s/data-cron-job.yaml`): runs
`bundle exec rake check_data` hourly; reads zip from CIFS mount at
`/mnt/legacy_cifs_middle_english_prep`.

---

## 12. Database

PostgreSQL via ActiveRecord. Only used for Blacklight's saved searches and
bookmarks. No application-domain data is in the database — all MED content
lives in Solr.

```yaml
# config/database.yml
adapter: postgresql
host: db
username: postgres
password: postgres
database: dromedary-<environment>
```

Migrations:
- `create_searches` (Blacklight)
- `create_bookmarks` (Blacklight)
- `add_polymorphic_type_to_bookmarks` (Blacklight)
- ActiveStorage migrations (present but feature not actively used)

---

## 13. Maintenance Mode

- **Enable:** `bin/dromedary maintenance_mode on` — creates `tmp/MAINTENANCE_MODE_ENABLED`
- **Disable:** `bin/dromedary maintenance_mode off` — removes the file
- **Effect:** route constraint `*path => static#maintenance_mode` catches all requests

Also enabled programmatically during the legacy `ExtractConvertIndex` pipeline.

---

## 14. Logging

**File:** `config/application.rb`

In production, a `JSON_FORMATTER` lambda formats log entries as JSON:
- Adds `application: 'MED'`
- Promotes `ip` from `named_tags` to top level
- Strips `utf8` parameter from payloads

`SemanticLogger::Loggable` is included in indexing classes for structured
logging during data processing.

---

## 15. Presenters

All presenters inherit from `Blacklight::DocumentPresenter` and include
`CommonPresenters` (`app/presenters/common_presenters.rb`):

- `hl_field(document, field)`: returns highlight-markup values if available, falls back to raw field values
- `first_found_value_as_highlighted_array(document, fields, default)`: returns first non-empty highlighted field from a priority list

Each controller has a dedicated presenter:
- `Dromedary::IndexPresenter` — dictionary (entry) results
- `Dromedary::Bib::IndexPresenter` — bibliography results
- `Dromedary::Quotes::IndexPresenter` — quotation results

---

## 16. Docker / Kubernetes Deployment

### Local Dev (docker-compose)

**File:** `compose.yml`

Services:
| Service | Image | Purpose |
|---------|-------|---------|
| `app` | `dromedary` (local build) | Rails app + puma; also runs indexing commands |
| `db` | `postgres:16-alpine` | PostgreSQL |
| `solr` | `solr/Dockerfile` (local build) | SolrCloud node |
| `zoo` | `zookeeper` | ZooKeeper for SolrCloud |

Key env in compose:
```
SOLR_ROOT=http://solr:8983/
SOLR_COLLECTION=med-preview
SOLR_COLLECTION_BASE=med
SOLR_USERNAME=solr
SOLR_PASSWORD=SolrRocks
SOLR_REPLICATION_FACTOR=1
DATA_ROOT=/mec/data
BUILD_ROOT=/mec/data/build
ALLOW_ADMIN_ACCESS=1
RAILS_RELATIVE_URL_ROOT=/m/middle-english-dictionary
DIRECT_URLS_TO_SOLR_REPLICAS=http://solr:8983 http://solr:8983
MANUALLY_BUILD_SUGGESTERS=true
```

Optional `.app.env` file loaded if present (for secrets not in compose).

### Production (Kubernetes)

**Directory:** `kubernetes/remote-k8s/`

- `app-deployment.yaml`: one pod with two containers:
  - `web` — Rails puma server
  - `sidekiq` — Sidekiq worker (runs `bundle exec sidekiq -r ./app/jobs/job_index.rb`)
  - `SOLR_PASS` read from K8s Secret `middle-english-solrcloud-security-bootstrap`
  - Data on PVC (`data-prep`) + CIFS hostPath mount for source zip
- `data-cron-job.yaml`: CronJob running `rake check_data` hourly
- `data-job.yaml`: one-shot data job
- Ingresses: `proxied-ingress.yaml`, `web-ingress.yaml`

### Docker Images

**App Dockerfile** (multi-stage):
- `base` — Ruby 3.3.8 slim + system deps
- `gems-dev` / `gems-prod` — bundler install
- `development` — dev image with full source
- `production` — assets precompiled, slim runtime
  - `SOLR_ROOT=bogus` and `SOLR_COLLECTION=bogus` set at build time to satisfy
    `Services` during `assets:precompile` (Services is lazy but routes.rb
    evaluates `Services[:rails_url_host]` at load time)

**Solr Dockerfile** (`solr/Dockerfile`):
- Based on `solr:10.0.0`
- Enables `analysis-extras` (ICU tokenizer/folder)
- Sets basic auth: `solr:SolrRocks`
- Custom `solr_init.sh` entrypoint

---

## 17. Health Checks

`/status` — OkComputer engine (mounted at root via `mount OkComputer::Engine, at: "/status"`).
`OkComputer.mount_at = false` in the initializer (not re-mounted internally).

---

## 18. Key Data Flows

### A. User Search Query

```
Browser GET /dictionary?q=horse&search_field=h
  -> Rack middleware (ExplicitProxyHost, ScriptNameFix)
  -> CatalogController#index
  -> Blacklight::Catalog#search_service
  -> Blacklight::Solr::Repository
  -> Solr /search handler (via Services[:solr_url])
  -> @response + @document_list (SolrDocument objects)
  -> Dromedary::IndexPresenter (hl_field, highlights)
  -> HTML via Blacklight views + Dromedary partials
```

### B. Autocomplete Request

```
Browser GET /dictionary/suggest?q=ho&search_field=h
  -> CatalogController#suggest
  -> looks up config/autocomplete.yml: h -> headword_only_suggester
  -> Solr GET /headword_only_suggester?q=ho
  -> gets suggestion terms
  -> secondary Solr GET /search?q="horse" qf=headword (to resolve IDs)
  -> returns HTML <li> fragments
```

### C. Data Indexing (Modern Pipeline)

```
Admin uploads zip (via Shrine -> S3)
  OR zip already on CIFS at /mnt/legacy_cifs_middle_english_prep/All_MED_and_Bib_files.zip

bin/dromedary prepare <zipfile> [--build_directory=...]
  -> Extract: unzip -> build_dir/xml/{A/,B/,...,links/,bib_all.xml}
  -> Convert:
     - load OED/DOE link files
     - parse each MED_*.xml -> MiddleEnglishDictionary::Entry
     - write each entry as JSON line -> build_dir/entries.json.gz (temp -> final)
     - create hyp_to_bibid.json from bib_all.xml

bin/dromedary index new_data
  -> create Solr configset from solr/dromedary/conf/
  -> create Solr collection "med_<timestamp>" with configset
  -> Traject(main_indexing_rules.rb):
     - reads entries.json.gz via EntryJsonReader
     - indexes entry fields + quotes
     - batch-commits 250 docs at a time
     -> new Solr collection
  -> Traject(bib_indexing_rules.rb):
     - reads bib_all.xml via BibReader
     - indexes bib fields
     -> new Solr collection
  -> rebuild suggesters (on all replicas if MANUALLY_BUILD_SUGGESTERS)
  -> set med-preview alias -> new collection

Admin UI: release
  -> delete old med-production alias
  -> create med-production alias -> preview collection
  -> (preview and production now point at same collection)
```

### D. HYP ID -> BIB ID Redirect

```
Browser GET /bibliography/HYPID123
  -> BibliographyController#show
  -> if /HYP/ in id: look up Dromedary.hyp_to_bibid[id]
     (loaded at boot from Solr or hyp_to_bibid.json)
  -> redirect 301 to /bibliography/<BIB_ID>
```

---

## 19. External Dependencies

| Gem / Service | Role |
|---------------|------|
| `blacklight` (~9.x) | Search UI framework |
| `middle_english_dictionary` (1.9.1) | Domain model: parse MED XML -> Entry/BibSet objects |
| `traject` | ETL pipeline for Solr indexing |
| `solr_cloud-connection` (vendored) | SolrCloud admin client: create collections, aliases, configsets |
| `canister` | Lazy DI container for Services |
| `ettin` | Multi-file config (not heavily used; ENV is authoritative) |
| `shrine` + `aws-sdk-s3` + `uppy-s3_multipart` | Zip file upload via S3 |
| `sidekiq` + `redis` | Background jobs |
| `semantic_logger` | Structured logging |
| `okcomputer` | Health check endpoint |
| `hanami-cli` | CLI framework for `bin/dromedary` commands |
| `my_simple_solr_client` (local lib) | Low-level Solr HTTP client (used by indexer CLI) |
| PostgreSQL | Saved searches + bookmarks only |

---

## 20. Known Quirks and Gotchas

1. **SearchBuilder is disabled.** The custom `SearchBuilder` class exists but is
   commented out in all controllers. The default Blacklight SearchBuilder runs.
   Planned: yogh/ezh substitution, paren escaping, dash escaping.

2. **`ExtractConvertIndex` may be broken.** The legacy all-in-one pipeline passes
   wrong keyword args (`datadir:` instead of `build_directory:`) to `Extract` and
   `Convert`. Use the split `prepare` + `index new_data` commands instead.

3. **`SOLR_ROOT=bogus` in Dockerfile.** Required because `config/routes.rb`
   `require "dromedary/services"` triggers `Services` evaluation at asset-precompile
   time. The placeholder values prevent a crash; actual Solr is not contacted.

4. **HYP IDs have backslashes** — `bib.hyps.each { |hyp| acc[hyp.delete("\\").upcase] }`.
   TODO comment in convert.rb says to remove this when backslashes are removed
   from source data.

5. **Proxy URL handling.** Three layers:
   - `ExplicitProxyHost` middleware injects `X-Forwarded-Host`
   - `routes_proxy_script_name_fix.rb` works around a Rails 5.2 `merge_script_names` crash
   - `routes.rb` sets `default_url_options[:host]` from `Services[:rails_url_host]`

6. **`PAUSE_TIME`** in compose.yml — used by init scripts, not by the app itself.

7. **`OkComputer.mount_at = false`** — health checks are at `/status` via the
   route mount, not re-mounted inside OkComputer itself.

8. **Solr SolrCloud but single-node in dev.** `ZK_HOST=zoo:2181` is set in
   compose, but `SOLR_REPLICATION_FACTOR=1`. SolrCloud API is always used.

9. **`solr_cloud-connection` is vendored** at `vendor/solr_cloud-connection/`.
   It is not fetched from a gem server.
