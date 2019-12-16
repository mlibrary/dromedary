# Setting up autocomplete for multiple input boxes

The blacklight autocomplete setup is pretty brittle and needs some mucking
about with to get it to work with multiple different input boxes that
target different solr autocomplete endpoints. 

## Three things that need doing
* Add a new autocomplete handler in the solr config
* Make changes to `config/autocomplete.yml`
* Add the option to the dropdown where the users determines what to search

If you're adding a whole new autocomplete input field in the HTML,
you'll also need to:
* Create the input box with  
* Make changes to `autocomplete.js.erb` 


## Configure the new autocomplete handler in the solr config

Suggesters live in `solr/med/conf/solrconfig_med/suggesters`. You 
can pattern a new one off of the ones in there.

Of course, if you're using an existing handler in a new context (say,
you want autocomplete for headwords again in an advanced search box), you 
can just use the handler that's already been defined and skip ahead to 
making and configuring the new search input field and dropdown.

Things to note:
* The name in `<str name=-name...>` in the top section is any name you
make up to identify this suggester. 
* ... but the `suggest.dictionary` in the bottom section *must* match that name
* ... and same with the `<arr name="components"...>` in the bottom
* The `field` is the name of the field you're basing this on. It *must*
be a stored field!
* `"suggestAnalyzerFieldType"` is probably the same fieldType used for the
field you're indexing in this typeahead field, but if you have the know-how
and think it should be different, go for it.


## Add new suggester to autocomplete in `config/autocomplete.yml`

```yaml
# Autocomplete setup.
# The format is:
#   search_name:
#     solr_endpoint: path_to_solr_handler
#     search_component_name: mySuggester
#
# The search_name is the name given the search in the
# `config.add_search_field(name, ...)` in catalog_controller
#
# The "keyword" config mirrors the default blacklight setup

default: &default
  keyword: 
    solr_endpoint: path_to_solr_handler,
    search_component_name: "mySuggester"
  h:
    solr_endpoint:         headword_only_suggester
    search_component_name: headword_only_suggester
  hnf:
    solr_endpoint:         headword_and_forms_suggester
    search_component_name: headword_and_forms_suggester
  oed:
    solr_endpoint:         oed_suggester
    search_component_name: oed_suggester

development:
  <<: *default

test:
  <<: *default

production:
  <<: *default

```

## Catalog controller configuration

Now load the autocomplete setup into your blacklight configuration.

```ruby

# Autocomplete on multiple fields. See config/autocomplete.yml
config.autocomplete = ActiveSupport::HashWithIndifferentAccess.new Rails.application.config_for(:autocomplete)

```

## Adding a whole new dropdown
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
is in `config/initializers/autcomplete_override_code.rb`

If Blacklight ever changes the autocomplete setup to allow this sort of
thing, we'll need to re-evaluate whether these extensions are necessary.
