# Overview of the indexing process

Indexing the MED data is a little different than most of what we
do in that it's not really _data_. What we have is 50k
little _documents_, and trying to treat them as data lost
about six weeks when we started this project.

**The only source of truth for what happens during indexing** is 
the steps in the file [indexing_steps.rb](../lib/med_installer/indexing_steps.rb).
At one point this was all driven by a CLI application, and there are still
vestiges of it lying around (including some calls to the old CLI code
in that file).

Details about access to solr and such are pulled in through 
environment variables. See [configuartion](configuration.rb) 
for a few more details.

The indexing process has a few steps:

* **Unzip** the file. This assumes the structure it's always had,
  with smaller zip files within it for each letter.
* **Extract XML files** and for each one create: 
  * a `MiddleEnglishDictionary::Entry` object
  * various bibliography-related objects (manuscript, stencil, etc.)
  * a more useful mapping to the external dictionaries (Dictionary of Old Enlish
    and the Oxford English Dictionary)
  * **Create the solr configset and collection** based on values
    from `services.rb`. We make a new configset every time, even though
    it hardly ever changes, because it's cheap and less confusing.
  * **Index the solr documents** using `traject` and two rules sets:
    * [main_indexing_rules](../indexer/main_indexing_rules.rb) does most of
      the heavy lifting, both building indexes and stuffing the actual 
      XML snippets into the solr document for later display. It loads up the
      [quote_indexer.rb](../indexer/quote/quote_indexer.rb) as well.
    * [bib_indexing_rules](../indexing/bib_indexing_rules.rb) are, obviously,
      more focused on the bibliographic data (author, manuscript, etc.).
  * **Create the "hyperbib" mapping file**. The bibliographic bits used
    to be called the "HyperBib" (back when "Hyper" meant "HyperMedia"). A 
    file mapping bibliographic entries to word entries is created
    and stored in solr as a single unique record  (with `type=hyp_to_bibid`).
    It's read into memory when the application boots up or the alias
    changes which underlying collection it's connected to.
  * **Build the suggester indexes**. The MED has several `suggester` handlers
    defined in the solr config which are used to provide field-specific
    typeahead in the search box. These are "built" by sending Solr a
    command to build them.
  * **Move the `med-preview alias`**. Upon completion, the collection alias
    `med-preview` will be swapped from the collection is was pointing at
    before to the one we just created. The "release" is just doing the
    same thing with the `med-production` alias. 

Again: the only code that runs during indexing is the stuff in or referenced
by [indexing_steps.rb](../lib/med_installer/indexing_steps.rb). I've run the 
indexer under code coverage culled from that, but there's no
guarantee that there isn't some dead indexing code lying in wait for the
unprepared.

## XSLT Files

The MED has been using XSLT to transform the little XML documents into something else
since the beginning, and we leveraged that knowledge to develop this version.

Essentially, the XSL is used to pull the data we want out of the XML files. 
An attempt was initially made to treat the XML as just a serialization of 
an underlying data model, but the structures vary wildly. Treating each
file as a _document_ is the model under which they were created, and we
eventually followed suit.
