# Next Steps

## Remove `config/initializers/autocomplete_override_code.rb`

This initializer is dead code and can be safely deleted.

### What it does
- Prepends `Dromedary::Suggest::SearchOverride` into `Blacklight::SuggestSearch` to support
  multiple autocomplete configs (keyed by `autocomplete_config` param)
- Defines a custom `Dromedary::Suggest::Response` that reads from a configured `@suggest_key`

### Why it's no longer needed (Blacklight 9)

1. **Controller fully overrides `suggest`** — `CatalogController#suggest` (line 328) directly
   calls `repository.connection.send_and_receive` and never instantiates `Blacklight::SuggestSearch`.
   The prepend never fires.

2. **`Dromedary::Suggest::Response` is unused** — the controller calls
   `Blacklight::Suggest::Response.new(...)` directly; the custom subclass is never referenced.

3. **BL9 `Blacklight::Suggest::Response`** now takes `(response, request_params, suggest_path, suggester_name)`
   as separate positional args, which is already what the controller passes. The old override
   existed partly to adapt the old single-arg API.

4. **The controller comment says "Override BL7 suggest"** — confirming the initializer was the
   BL7-era approach, since superseded by the in-controller override.

### Action
Delete `config/initializers/autocomplete_override_code.rb`. The `Dromedary::Suggest` namespace
is defined nowhere else and has no other references.
