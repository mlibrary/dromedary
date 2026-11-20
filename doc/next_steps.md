# Next Steps After YARD Documentation Pass

Generated May 2026. See also `doc/yard_pass_notes.md` for full bug/removal inventory.

> Status: Legacy `bin/dromedary` cleanup is complete. Its CLI-only code and
> indexing jobs were removed without replacements; affected recommendations
> below are historical.

---

## 1. Remove legacy `Index::HypToBibID`

**Status:** Removed with `lib/med_installer/index.rb`. The active
`MedInstaller::HypToBibId` module remains; no CLI replacement was added.

---

## 2. Remove `MedInstaller::ExtractConvertIndex`

**Status:** Deleted with the legacy CLI. No replacement command was added.

---

## 3. Remove pre-container dead code

The following historical audit items were removed with the legacy CLI cleanup.

### Solr install/management classes (in `med_installer/solr.rb`)
- `MedInstaller::Solr::Install` -- downloads Solr 6.6.3; container-era obsolete
- `MedInstaller::Solr::Link` -- symlinks local configs; obsolete
- `MedInstaller::Solr::Start` / `Stop` -- manages local Solr process; obsolete
- `MedInstaller::Solr.rebuild_suggesters` (class method) -- superseded by
  `IndexingSteps#rebuild_suggesters`; the CLI command `RebuildSuggesters` delegates
  to it and should also be removed or updated
- `MedInstaller::Solr.get_port_with_logging` -- no usages found

### AnnoyingUtilities methods with no callers
- `#solr_root`
- `#solr_port`
- `#blacklight_config_file`
- `#target_directories`

### MySimpleSolrClient::Client unimplemented stubs
All of the following raise `"Not Implemented Yet"` and have unreachable code after
the raise: `url`, `ping`, `system`, `version`, `major_version`, `new_core`,
`temp_core`, `temp_core_dir_setup`, `unload_temp_cores`.

### Remote deployment classes
`MedInstaller::Remote` and its subcommands (`Deploy`, `Restart`, `Dromedary`, `Exec`)
use an `ssh deployhost` convention that is likely obsolete under Kubernetes. Confirm
with the ops team before deleting.

### Dead private methods in `convert.rb`
`start_new_letter` and `letter_and_filename` are defined but never called.

**Status:** The legacy Solr, remote deployment, and CLI-only utility code listed
above was removed. No replacement CLI was added.

---

## 4. Fix `dromedary/forms/search_form.rb`

**Problem:** Line 4 has `incude` (typo for `include`). The file is otherwise an empty
stub. It is unclear whether it is loaded anywhere outside `lib/` (e.g. Rails
autoload).

**Suggested fix:**
1. Search the Rails app for references to `SearchForm` or `Dromedary::Forms`.
2. If unused: delete the file.
3. If used: fix the typo and flesh out the class.

---

## 5. Confirm `stencil_author` / `stencil_title` omission from `IndexableQuoteRepresenter`

**Situation:** `IndexableQuote#initialize` sets both `stencil_author` and
`stencil_title` (from the bib stencil), but `IndexableQuoteRepresenter` does not
declare properties for either. The current YARD doc notes this as intentional because
they duplicate `author` and `title`.

**Action needed:** Confirm the omission is deliberate. If confirmed, no code change
is required -- the YARD note stands. If they should be included, add:

```ruby
property :stencil_author
property :stencil_title
```

---

## 6. Remove legacy `Index::Generic`

**Status:** Removed with the old indexing commands. The active pipeline uses the
configured writer directly; no replacement CLI was added.

---

## 7. Clarify `Services[:looks_like_first_upload]` consumers

**Situation:** The service returns `true` when `allow_admin_access` is set and the
current Solr collection is `nil`. The purpose is to suppress misleading warnings on
a fresh install. It is not obvious from `lib/` which Rails controllers or views
consume this value.

**Action needed:** Search the Rails app (`app/`) for `looks_like_first_upload` and
document the callers. If none exist, remove the service registration.

**Update (dead code scan):** `rg` across all file types found `looks_like_first_upload`
referenced in `app/views/shared/_footer.html.erb`. The service is live. No action needed.

---

## 8. Dead Code Confirmed by Full Cross-Reference Scan (May 2026)

The items below were identified by a systematic scan of all lib/, app/, indexer/, bin/,
and config/ source. Each was checked with IntelliJ `find_references` and `rg` before
listing. Unless noted, all have zero callers and are safe to delete.

### Update: item 4 (search_form.rb) confirmed dead

`rg` across the entire repo found `SearchForm` referenced only inside the file itself and
in these notes. Delete `lib/dromedary/forms/search_form.rb`.

---

### 8a. Commented-out CLI commands still present in lib/

The following installer command classes were removed with the legacy CLI cleanup; no
replacement commands were added.

**In `lib/med_installer/solr.rb`:**
- `MedInstaller::Solr::Commit` -- manual Solr commit; automated post-index
- `MedInstaller::Solr::Optimize` -- local Solr optimize; container-era obsolete
- `MedInstaller::Solr::Reload` -- local Solr reload; obsolete
- `MedInstaller::Solr::Empty` -- empties Solr collection via `MySimpleSolrClient`; obsolete
- `MedInstaller::Solr::Up` -- polls Solr HTTP until up; superseded by container health checks
- `MedInstaller::Solr::Shell` -- opens IRB with a Solr client bound; dev tool only

(Note: `Install`, `Link`, `Start`, `Stop`, and `get_port_with_logging` are already listed
under item 3 above.)

**In `lib/med_installer/control.rb`:**
- `MedInstaller::Control::MaintenanceModeOn` and `MaintenanceModeOff` were removed
  with the legacy CLI. The Rails route still reads the maintenance flag.

**In `lib/med_installer/ping_prometheus.rb`:**
- `MedInstaller::PingPrometheus` -- removed with the legacy CLI

---

### 8b. Dead installer command classes with zero callers

`MedInstaller::Index::Entries` and `MedInstaller::Index::Bib` were removed with
`lib/med_installer/index.rb`; the active pipeline uses its Traject rules directly.

---

### 8c. Dead serialization code

`IndexableQuoteRepresenter` in `lib/serialization/indexable_quote.rb` -- `IndexableQuote`
itself is used by the indexer, but `IndexableQuoteRepresenter` has zero callers anywhere
in the project. Delete the representer class (lines below `IndexableQuote`) or the entire
file if `IndexableQuote` is refactored to not need a separate representer.

---

### 8d. Dead method inside a live class

`BibReader#get_data_file` was removed; the reader uses its configured service path.

---

### 8e. Unrouted Rails controller

`UpdatesController` in `app/controllers/updates_controller.rb` -- routes.rb has no route
pointing to any action in this controller. Its view `app/views/updates/index.html.erb` is
also unreachable. Delete both.

---

### 8f. Archived / shadow view files

`app/views/catalog/original_blacklight_views/` -- a directory containing 20+ files that
appear to be copies of the original Blacklight gem views kept as a reference snapshot.
They are never rendered; Rails resolves views from `app/views/catalog/` directly. Delete
the entire `original_blacklight_views/` subdirectory. If you need the originals for
reference, the Blacklight gem source is the authoritative copy.

`app/views/catalog/print.html.erb` -- the print show-tool is commented out in
`CatalogController` (`# add_show_tools_partial(:print, ...)`). The template is
unreachable. Delete it or re-enable the show-tool.

---

### 8g. Commented-out controller method

`AdminController#current_state` in `app/controllers/admin_controller.rb` -- the method
body is entirely commented out. If the action is not planned for near-term revival,
remove the method stub.

---

### 8h. Developer debug scripts checked in to the repo

The following files contain `binding.pry` calls and are clearly not production code:

- `indexer/pry_session.rb` -- opens a pry REPL with indexer context loaded; delete or
  move to a scratch/ gitignored directory
- `indexer/solr_shell.rb` -- removed with the legacy Solr client
- `t.rb` (repo root) -- a `Concurrent::TimerTask` that prints "Hello" and sleeps 1000
  seconds; scratch file, delete

**Also:** `bin/batch_send_jsonl.rb` requires `authority_browse/connection` (a gem not in
this project's Gemfile), and its rescue block calls `require "pry"; binding.pry`. This is
a debug/prototype script, not production tooling. Delete or move outside the repo.

---

### 8i. Legacy IndexDataJob removed

`IndexDataJob`, its Rake tasks, and the old Kubernetes data jobs were removed.
No replacement job or trigger was added.

---

### Summary counts

| Area | Items |
|------|-------|
| lib/ commented-out CLI classes | 10 |
| lib/ dead installer classes (Entries, Bib) | 2 |
| lib/ dead serialization (IndexableQuoteRepresenter) | 1 |
| lib/ dead method (BibReader#get_data_file) | 1 |
| lib/ dead file (search_form.rb) | 1 |
| app/ unrouted controller + view | 2 |
| app/views archive directory | 1 dir (~20+ files) |
| app/ dead view (print.html.erb) | 1 |
| app/ commented-out method (AdminController#current_state) | 1 |
| Debug scripts (pry_session, solr_shell, t.rb, batch_send_jsonl) | 4 |
| **Total** | **~44 files/items** |
