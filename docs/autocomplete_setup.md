# Setting up autocomplete for multiple input boxes

The blacklight autocomplete setup is pretty brittle and needs some mucking
about with to get it to work with multiple different input boxes that
target different solr autocomplete endpoints. 

## Three things that needed doing
* Add a new autocomplete handler in the solr config
* Make changes to `config/autocomplete.yml`
* Add javascript code to trigger autocomplete
  to the dropdown where the users determine what to search

## Configure the new autocomplete handler in the solr config

Suggesters live in 
[solr/dromedary/conf/solrconfig_med/suggesters](../solr/dromedary/conf/solrconfig_med/suggesters). 
You can pattern a new one off of the ones in there.

Of course, if you're using an existing handler in a new context (say,
you want autocomplete for headwords again in an advanced search box), you 
can just use the handler that's already been defined and skip ahead to 
making and configuring the new search input field and dropdown.

Things to note:

* You can pick any names for the suggester handler, but it
  must be used _identically_ in three places:
  * The top `<str name=-name...>`
  * The name of the `suggest.dictionary`
  * The reference in the `<arr name="components"...>` block.
* The `field` is the name of the field you're basing this on. It *must*
be a stored field! The code we have now builds a special field for this
instead of trying to force an existing field to work.
* `"suggestAnalyzerFieldType"` is probably the same fieldType used for the
field you're indexing in this typeahead field, but if you have the know-how
and think it should be different, go for it.


## Add new suggester to the autocomplete configuration
Pattern match from another entry 
and add it to [autocomplete.yml](../config/autocomplete.yml)

## Catalog controller configuration

```ruby

# Autocomplete on multiple fields. See config/autocomplete.yml
config.autocomplete = ActiveSupport::HashWithIndifferentAccess.new Rails.application.config_for(:autocomplete)

```

## Adding a whole different search box

I don't expect this will happen at this point, but the knowledge may 
well come in handy on other project.

### Adding a whole new dropdown

* Put a data attribute `data-autocomplete-config` on your text box
    to reference which typeahead configuration should be used (e.g,
    `h` or `hnf` in the config example above). 
* Put a data attribute `data-autocomplete-controller` with the ID of
    your "pick what you want to search" dropdown to let the latter
    control which autocomplete configuration is used.

### The "more details" you may not need
    
In the javascript, we count on the input box having a data attribute called
`autocomplete-config` that holds the name of the typeahead configuration
in `config/autocomplete.yml` as shown above.

`autocomplete.js.erb` has been altered to send the value of this
data element along in the call to the blacklight application as `autocomplete_config`.

It is also set up to allow the autocomplete target to change based on the 
currently selected option in a drop-down. 

If an input box is set for autocomplete *and* has a data element called
`autocomplete-controller` that holds the id of such a dropdown, 
`autocomplete-config` will automatically be set whenever the drop-down
selection is changed. This is how autocomplete is automatically set to use
the correct index when a user picks, e.g., "headword only."

## Side note: this overrides blacklight code

I don't actually moneky-patch, but I do use `Module#prepend`. The code
is in [autocomplete_override_code.rb](../config/initializers/autocomplete_override_code.rb).

