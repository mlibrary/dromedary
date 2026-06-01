# Next Steps After YARD Documentation Pass

Generated May 2026. See also `doc/yard_pass_notes.md` for full bug/removal inventory.

---

## 1. Add `AnnoyingUtilities.hyp_to_bibid_path`

**Problem:** `Index::HypToBibID#write_hyp_to_bib_id` calls
`AnnoyingUtilities.hyp_to_bibid_path` but that method does not exist. The command
raises `NoMethodError` at runtime.

**Suggested fix:** Add the method to `AnnoyingUtilities`:

```ruby
# @return [Pathname] path to +hyp_to_bibid.json+ in the build directory
def hyp_to_bibid_path
  build_directory + "hyp_to_bibid.json"
end
```

**Confirm:** Is `Index::HypToBibID` still an active code path, or has it been
entirely superseded by `IndexingSteps#upload_hyp_to_bibid_to_solr`? If superseded,
delete `Index::HypToBibID` instead.

---

## 2. Fix or delete `MedInstaller::ExtractConvertIndex`

**Problem:** `extract_convert_index.rb` passes `datadir:` to `Extract` and
`source_dir:` to `Convert`, but both expect `build_directory:`. The command cannot
run successfully in its current state.

**Suggested fix:** Delete the file. It is superseded by the `Prepare` + `IndexNewData`
command pair, which use the correct keyword arguments. If there is a reason to keep
it, fix the keyword names to `build_directory:` and add integration tests.

---

## 3. Remove pre-container dead code

The following are candidates for deletion. All predate the containerised Solr
deployment and have no active callers.

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

**Suggested approach:** Open a single PR titled "Remove pre-container dead code",
address each item above, and verify the CLI command list in `bin/dromedary` still
registers cleanly.

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

## 6. Replace `Index::Generic#select_writer` with a Services lookup

**Problem:** `select_writer` hard-codes `writers/localhost.rb` for the non-debug path,
targeting a local Solr instance. The containerised pipeline uses
`Services[:solr_writer]` (already used in `IndexingSteps`).

**Suggested fix:** Replace the non-debug branch:

```ruby
def select_writer(debug)
  if debug
    index_dir + "writers" + "debug.rb"
  else
    Dromedary::Services[:solr_writer]
  end
end
```

This unifies the writer selection with `IndexingSteps` and removes the implicit
dependency on a local Solr installation.

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

The following installer command classes remain in source but their `bin/dromedary`
registrations are commented out. They have zero callers and should be deleted along with
the commented-out `bin/dromedary` lines.

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
- `MedInstaller::Control::MaintenanceModeOn` -- **NOT dead**: called programmatically
  from `Index::Full#call` (index.rb line 229) even though the CLI registration is commented
  out. Keep.
- `MedInstaller::Control::MaintenanceModeOff` -- same; called from `Index::Full#call`
  (index.rb line 249). Keep.

**In `lib/med_installer/ping_prometheus.rb`:**
- `MedInstaller::PingPrometheus` -- entire file; CLI commented out, zero callers

---

### 8b. Dead installer command classes with zero callers

`MedInstaller::Index::Entries` and `MedInstaller::Index::Bib` -- these were only ever
called by `ExtractConvertIndex` (item 2 above, itself slated for deletion). With that
gone, both classes are unreachable. They live in `lib/med_installer/index.rb` and can be
deleted after `ExtractConvertIndex` is removed.

---

### 8c. Dead serialization code

`IndexableQuoteRepresenter` in `lib/serialization/indexable_quote.rb` -- `IndexableQuote`
itself is used by the indexer, but `IndexableQuoteRepresenter` has zero callers anywhere
in the project. Delete the representer class (lines below `IndexableQuote`) or the entire
file if `IndexableQuote` is refactored to not need a separate representer.

---

### 8d. Dead method inside a live class

`BibReader#get_data_file` in `lib/med_installer/indexer/bib_reader.rb` -- the method is
defined but `@data_file` is set unconditionally in `initialize` and `get_data_file` is
never called. Delete the method.

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
- `indexer/solr_shell.rb` -- opens a pry REPL with a `MySimpleSolrClient` connection;
  same recommendation
- `t.rb` (repo root) -- a `Concurrent::TimerTask` that prints "Hello" and sleeps 1000
  seconds; scratch file, delete

**Also:** `bin/batch_send_jsonl.rb` requires `authority_browse/connection` (a gem not in
this project's Gemfile), and its rescue block calls `require "pry"; binding.pry`. This is
a debug/prototype script, not production tooling. Delete or move outside the repo.

---

### 8i. Cascading bug: IndexDataJob calls broken command

`IndexDataJob` (in `app/jobs/index_data_job.rb`) calls `MedInstaller::ExtractConvertIndex`
-- the same command identified as broken in item 2. The Rake tasks `:queue_indexing` and
`:perform_indexing` invoke this job. After deleting `ExtractConvertIndex` (item 2), update
`IndexDataJob` to call the correct replacement pipeline (`Prepare` + `IndexNewData`) or
delete the job if it is no longer the intended indexing path.

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
