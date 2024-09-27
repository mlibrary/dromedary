# Solr configuration for the MED

The MED data isn't super-complicated, and the solr install follows suit.

There are a few things worth noting.

## Use of XML ENTITY declarations to include files

The configuration makes use of XML includes (the `ENTITY` declarations
that pull in other files) to keep things a little easier to manage.
For both the `solrconfig.xml` and (to a lesser extent) the
`schema.xml` files, the most interesting stuff is in the 
subdirectories, implemented as files expanded into the
main configuration.

## Extra .jar file

Additional .jar files are used, in particular the ICU code for
both tokenization and normalization. The necessary files are located
in [solr/lib](../solr/lib) and are copied into the image via the
[solr Dockerfile](../solr/Dockerfile)

## Search parameters defined in the solr configuration

The actual search parameters (what fields to search, relevance boosts, etc)
are actually in the solr configuration and just referenced in the
Blacklight code. So, when the CatalogController references
`$headword_and_forms_qf`, you need to look at 
[headword_and_forms_search.xml](../solr/dromedary/conf/solrconfig_med/entry_searches/headword_and_forms_search.xml)
to see what's going on and make changes. 

All the configuration assumes we're targeting an eDismax search handler.
There are `qf` and `pf` variables defined right in the `solrconfig.xml`
for each of the handlers, but those are there to act as defaults. The
"real" configuration is in the smaller, included XML files.

## Multiple search handlers

Most solr configurations at the library use a single primary handler for searches,
usually exposed as `select`. This `solrconfig.xml` uses several separate requestHandlers,
each tuned to what kind of search the user is doing:
* _search_ for entries 
* _bibsearch_ for bibliography, and 
* _quotesearch_ for quotation searches.

There as also couple special handlers for dealing with individual documents 
and the hyp-to-bibid mapping record.
In all cases, what's in the actual `solrconfig.xml` file is a skeleton,
with the meat of the definitions in the files under 
[solrconfig_med](../solr/dromedary/conf/solrconfig_med)

## Multiple Suggesters

In solr parlance, a "suggester" is a handler and associated index 
designed expressly for doing autocomplete. Stock Blacklight only
deals with a single index, so some changes have been made
to allow distinct indexes to be used depending on what field
has been selected in the search dropdown.

Each suggester is built off a particular field, and needs to be rebuilt
whenever the index changes (which is done when doing a normal
indexing routine via the Admin page or locally with
[index_new_file.rb](../bin/index_new_file.rb)).

The suggester terminology is a bit opaque, so adding a new suggester is
probably best done by pattern matching on what's already there.

Here's an example, from [headword_only_suggester.xml](../solr/dromedary/conf/solrconfig_med/suggesters/headword_only_suggester.xml)

```xml
<searchComponent name="headword_only_suggester" class="solr.SuggestComponent">
  <lst name="suggester">
    &common_suggester_components;
    <str name="name">headword_only_suggester</str>
    <str name="suggestAnalyzerFieldType">me_text</str>
    <str name="field">headword_only_suggestions</str>
    <str name="storeDir">headword_only_suggester_index</str>

  </lst>
</searchComponent>

<requestHandler name="/headword_only_suggester" class="solr.SearchHandler"
                startup="lazy">
<lst name="defaults">
  <str name="suggest">true</str>
  <str name="suggest.count">15</str>
  <str name="suggest.dictionary">headword_only_suggester</str>
</lst>
<arr name="components">
  <str>headword_only_suggester</str>
</arr>
</requestHandler>

```

Things to note:

* You can pick any names for the suggester handler, but it
  must be used _identically_ in three places:
    * The top `<str name=-name...>` in the `searchComponent` at the top
    * The name of the `suggest.dictionary` in the `requestHandler`
    * The reference in the `<arr name="components"...>` block at the bottom.
* The `field` is the name of the field you're indexing. It *must*
  be a stored field! The current setup builds up a special field for this,
  instead of trying to make an existing field work.
* `"suggestAnalyzerFieldType"` is probably the same fieldType used for the
  field you're indexing in this typeahead field -- it controls what
  analysis chain (if any) is run on the data, and is just a refernce to
  a type as defined with a `fieldType` in your `schema.xml`. Generally,
  you'll want to use the same `fieldType` as you do for the data in
  the searchable parts of the index.

If you're building a new suggester for another field, you'll need to 
make sure to also reference it correctly in the search dropdown
and add it to [autocomplete.yml](../config/autocomplete.yml).