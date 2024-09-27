# Tour of the application code

In general, the MED is a "normal" Blacklight (v5) application, with a lot
of added stuff.

Like most Blacklight apps, the heart of the configuration is
in the [Catalog Controller](../app/controllers/catalog_controller.rb), 
specifying the search and facet fields. This is repeated for the
other controllers, and they're fairly straightforward so long as
you're willing to take on faith that Rails will find things at the
right time.


## Models
The files in [models](../app/models) are unusual for a Rails app in that we're not using
a backing database, and thus not deriving them from ActiveRecord.
The directly is empty of anything interesting.

The _actual_ objects to represent each of the many, many layers of a dictionary 
entry are actually defined in the [middle_english_dictionary](https://github.com/mlibrary/middle_english_dictionary)
repository. The nomenclature can be confusing, since it's derived from 
the jargon of the field, but none of the objects are particularly complex.

## Presenters

The meat of the interface is actually built into the presenters.
[quotes presenter](../app/presenters/quotes/index_presenter.rb) 
is indicative of the setup, pulling in lots of XSLT and getting values
out of the document with XSLT transforms or by querying the 
`Nokogiri::XML` document directly. 

## lib/med_installer

...is all indexing code, and isn't used in the rest of the application. See
[indexing.md](indexing.md) for a brief overview.

## /solr

...has all the solr configuration in it, as well as the
[Dockerfile](../solr/Dockerfile) and the [container initialization](../solr/container/solr_init.sh)
code. See [solr.md](solr.md) for more.

## Everything else

...is basically just normal views and utility objects
(most importantly the [services.rb](../lib/dromedary/services.rb) file). 






