# YARD Documentation — Post-Pass Notes

Generated during YARD documentation pass, May 2026.

---

## Bugs / Runtime Errors

1. **`annoying_utilities.rb:188` — `INITIALIZER_DIR` undefined**
   The `find_file` private method references `INITIALIZER_DIR` in its error string but
   that constant is never defined anywhere in the codebase. If a config file is not
   found in `CONFIG_DIR` the rescue message will raise `NameError` instead of the
   intended `RuntimeError`. The constant reference should be removed from the error
   string or the constant should be defined.

2. **`med_installer/index.rb:206` — `AnnoyingUtilities.hyp_to_bibid_path` undefined**
   `Index::HypToBibID#write_hyp_to_bib_id` calls `AnnoyingUtilities.hyp_to_bibid_path`
   but that method does not exist in `annoying_utilities.rb`. The command will raise
   `NoMethodError` at runtime. The method needs to be added to `AnnoyingUtilities`.

3. **`med_installer/copy_from_build.rb:48` — `Dromedary.config` undefined**
   `CopyFromBuild#call` uses `Dromedary.config.build_dir`. `Dromedary.config` is not
   defined in `lib/`; it would need to come from a Rails initializer. This command
   cannot be used outside a Rails context.

4. **`med_installer/extract_convert_index.rb:43/47` — wrong keyword arguments**
   `ExtractConvertIndex` passes `datadir:` to `Extract` and `source_dir:` to
   `Convert`, but both expect `build_directory:`. This command is broken and cannot
   run successfully.

5. **`dromedary/forms/search_form.rb:4` — `incude` typo**
   Line 4 has `incude` instead of `include`. The file is an empty stub; unclear
   whether it is used at all.

---

## Code Not Fully Understood (not documented)

1. **`IndexableQuoteRepresenter`** (`serialization/indexable_quote.rb`)
   Uses `MiddleEnglishDictionary::Entry::CitationRepresenter` from an external gem.
   `stencil_author` and `stencil_title` are set on `IndexableQuote` at construction
   time but are absent from the representer. Unclear if that is intentional or an
   accidental omission.

2. **`dromedary/forms/search_form.rb`** — stub class with `incude` typo. Unclear
   if this file is used anywhere or was an abandoned experiment.

3. **`BibReader#get_data_file`** (`med_installer/indexer/bib_reader.rb`) — defined but
   `@data_file` in `initialize` ignores settings entirely; the method appears dead.

4. **`Services[:looks_like_first_upload]`** (`dromedary/services.rb`) — used in
    `app/views/shared/_footer.html.erb` to display refresh status. Returns `true`
    when admin access is allowed and the current collection is nil, which suppresses
    the "never refreshed" message on a fresh install. Live code.

5. **`MySimpleSolrClient::Client#rawclient`** — sets `@rawclient = HTTPClient.new` but
   `HTTPClient` is only used to set `receive_timeout` in `Index::Generic#core`. All
   actual HTTP requests go through the Faraday connection (`@solr_connection`). The
   `rawclient` accessor exists solely to expose the timeout setter.

---

## Candidates for Removal

### AnnoyingUtilities methods with no usages found
| Method | Reason |
|--------|--------|
| `#solr_root` | Solr runs in containers; no callers found |
| `#solr_port` | No callers found |
| `#blacklight_config_file` | No callers found |
| `#target_directories` | No callers found |

### MySimpleSolrClient::Client stub methods (all raise "Not Implemented Yet")
`url`, `ping`, `system`, `version`, `major_version`, `new_core`, `temp_core`,
`temp_core_dir_setup`, `unload_temp_cores`

### Pre-container Solr install/management classes
| Class | Reason |
|-------|--------|
| `MedInstaller::Solr::Install` | Downloads Solr 6.6.3; obsolete with containers |
| `MedInstaller::Solr::Link` | Symlinks local Solr configs; obsolete |
| `MedInstaller::Solr::Start` | Manages local Solr process; obsolete |
| `MedInstaller::Solr::Stop` | Manages local Solr process; obsolete |
| `MedInstaller::Solr.rebuild_suggesters` (class method) | Superseded by `IndexingSteps#rebuild_suggesters` |
| `MedInstaller::Solr.get_port_with_logging` | No usages found |

### Broken/superseded commands
| Class | Reason |
|-------|--------|
| `MedInstaller::ExtractConvertIndex` | Broken keyword args; superseded by `Prepare` + `IndexNewData` |
| `MedInstaller::Remote` (all subclasses) | Uses `ssh deployhost` convention; likely obsolete with k8s |

### Vestigial index writer
`MedInstaller::Index::Generic#select_writer` targets `writers/localhost.rb` for the
non-debug path. Containerised pipeline uses `Services[:solr_writer]` instead. The
`select_writer` method and the `localhost.rb` writer file are candidates for removal
(or replacement with a `Services`-backed lookup).

### Dead private methods in convert.rb
`start_new_letter` and `letter_and_filename` in `MedInstaller::Convert` are defined
but never called from within the file or anywhere else in the codebase.
