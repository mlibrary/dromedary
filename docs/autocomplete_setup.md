# Setting up autocomplete for multiple input boxes

The blacklight autocomplete setup is pretty brittle and needs some mucking
about with to get it to work with multiple different input boxes that
target different solr autocomplete endpoints. 

## Catalog controller configuration

You can set up multiple autocomplete configurations by doing the following
(which mirrors the default blacklight configuration)

```ruby

# Example
  config.autocomplete = {
       keyword: {
         solr_endpoint: path_to_solr_handler,
         search_component_name: "mySuggester"
       },
       # more configs here
  }

# Actual code is at the bottom of the catalog controller

    config.autocomplete = {
      h:   {
        solr_endpoint:         "headword_only_suggester",
        search_component_name: "headword_only_suggester"
      },
      hnf: {
        solr_endpoint:         "headword_and_forms_suggester",
        search_component_name: "headword_and_forms_suggester"
      },
      oed: {
        solr_endpoint:         "oed_suggester",
        search_component_name: "oed_suggester"
      }
    }



```

`keyword` is the name of the search in the
`config.add_search_field(name, ...)` and allows the search field picker
dropdown to control which configuration is used.




## autocomplete.js

**tl;dr**

  * Put a data attribute `data-autocomplete-config` on you text box
    to reference which typeahead configuration should be used.
  * Put a data attribute `data-autocomplete-controller` with the ID of
    your "pick what you want to search" dropdown to let the latter
    control which autocomplete configuration is used.
    
In the javascript, we count on the input box having a data attribute called
`autocomplete-config` that holds the name of the configuration name
in the blacklight config we just made above.

`autocomplete.js` has been altered to send the value of this
data element along in the call to the blacklight application as `autocomplete_config`.

It is also set up to allow the autocomplete target to change based on the 
currently selected option in a drop-down. 
If an input box is set for autocomplete *and* has a data element called
`autocomplete-controller` that holds the id of such a dropdown, 
`autocomplete-config` will automatically be set whenever the drop-down
selection is changed.

## Monkey-patching blacklight

I don't actually moneky-patch, but I do use `Module#prepend`. The code
is in `config/initializers/autcomplete_override_code.rb`
