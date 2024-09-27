# Configuration

Configuration of this application has...grown organically. Thus, lots
of things are spread out over a few locations.

## ./config

**The normal rails `config` directory** has all the "normal" stuff
in it, including the [`routes.rb`](../config/routes.rb) file which can be inspected to
understand what things are exposed.

Additions to the normal rails/blacklight stuff include:
  * [autocomplete.yml](../config/autocomplete.yml) configures the exposed
    names and the solr targets for each autocomplete field's `suggester` handler.
  * [autocomplete_overrid_code.rb](../config/initializers/autocomplete_override_code.rb), 
    which provides extra code (via `module prepend`) to deal with the fact
    that we're running multiple suggesters.
  * [load_local_config.rb](../config/load_local_config.rb) had so much 
    stripped away that it's now mostly utility code to reload the
    `hyp_to_bibid` data from the current solr and extract data from
    the name of the underlying collection. 

## Controllers

The [CatalogController](../app/controllers/catalog_controller.rb) is the heart
of any Blacklight application, specifying how to talk to solr, what fields to
expose as searchable, etc. We have controllers for all the different aspects
of the site (e.g., bibliography, quotes), so make sure you're looking at
the right one.

## Mystery Solr Configuration in the controllers

The solr configuration in the controllers includes variables that look like
`$everything_qf` where normally you'd have a list of fields. The decision was
made to actually store this configuration in _solr_, so sending that
magic reference will cause solr (on its end) to use the values defined in 
the XML up there. See ([headword_and_forms_search.xml](../solr/dromedary/conf/solrconfig_med/entry_searches/headword_and_forms_search.xml))
for a representative sample. 


## The Dromedary::Services object

The [services object](../lib/dromedary/services.rb) is really the heart of 
all the configuration. Every effort has been made to push everything 
though it, as opposed to directly using ENV variables and such.

Instead of just being a passthrough for the environment, though, the
Services object also includes useful things derived from those 
variables, including things like a connection object for the 
configured solr.

Essentially everything you need to understand how the application is
influence "from the outside" (e.g., the argocd config) is in this file.

## AnnoyingUtilities

The [annoying_utilities.rb](../lib/annoying_utilities.rb) file once did
all the little, annoying substitutions that were necessary to run the application 
on two relatively-different staging and production platforms. Now that
it's all container-based, all of that code has been ripped out and
replaced with thin wrappers around `Dromedary::Services`. Mentioned
here because it's still in the code in some places and might be
confusing.

