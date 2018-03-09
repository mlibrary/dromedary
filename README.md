# Dromedary -- Middle English Dictionary Application

This is the installation guide. 

There are a lot of moving parts, so let's go through them
one at a time.

## Set up a working direectory

  * Make a directory to hold everything (presumed to be named `med`)
    * `mkdir /some/path/to/med`
    * `cd /some/path/to/med`
    
From here on in we'll call this directory `/some/path/to/med`.

## Install the `dromedary` code
  * Clone the repo 
    * If you have two-factor on github: `git clone git@github.com:mlibrary/dromedary.git`
    * If not: `git clone https://github.com/mlibrary/dromedary`
    * `cd dromedary`
    * Due to changes with openssl on the mac you may have to export a library path to get the mysql2 gem to compile a local version (depends on where the library is installed by brew in my case): `export LIBRARY_PATH=/usr/local/Cellar/openssl/1.0.2n/lib`
    * `bundle install --path ./.bundle` 
    
The basic dromedary code is now ready for use.

## Set up solr

`dromedary` requires a solr installation to work. It's recommended you install
a version just for this project in your `med` directory

### Using a new solr

From your `dromedary` directory:

* `bin/dromedary solr install`

The convention is to install the solr "next to" your dromedary installation. If you 
want to put it somewhere else, just add the directory

* `bin/dromedary solr install /Users/dueber/mysolrstuff`

This will
* Download solr to the specified directory
* Untar it and get it all set up
* Automatically run `bin/dromedary solr link` to put the dromedary config in place

### Using your own solr

If you've already got a solr lying around, you can just use it.

* Edit `config/blacklight.yml` so the url/port are correct
* Create a file at `dromedary/.solr` with just one line: the path to your local solr install on disk
  (e.g., `echo /Users/dueberb/solr_stuff/solr-6.6.2 > .solr`)
* Run `bin/dromedary solr link` to set up symlinks in the right places so your solr can find the
  dromedary configuration
    
## Extract the raw data

The data is stored in little `.xml` files. We want to get them from the Box directory,
extract the little XML files from their enclosing `.zip` files, and then convert 
them to a different format (because ruby deals with XML *very* slowly).

  * Preparing to download with Safari. If you are using Apple's safari, you must disable auto-unzip feature so the following extract and convert instruction work correctly. Under the Safari/Preferences/General tab you must uncheck the checkbox for “Open safe files after downloading”.
  * Go to [the box folder](https://umich.app.box.com/s/ah2imm5webu32to343p2n6xur828zi5w)
   and hit the "Download" button in the upper-right to get a zip file called
   _In_progress_MEC_files_. Pay attention to where it goes -- almost certainly
   `~/Downloads` on a Macintosh.
  * `cd` into your `dromedary` directory
  * Pick a place for the data to go. You should probably use `/some/path/to/med/data`
    (the parent directory of your `dromedary` directory, so `../data` from where you are
    now) unless you have a good reason not to.
  * Extract the data to that place: 
    * `bin/dromedary extract /path/to/In_progress_MEC_files.zip ../data`
    
## Convert the little XML files into something faster/better

NOTE: You can skip this conversion step if you just get the already-converted json files
from Bill. The conversion process can take a looooong time.

* `bin/dromedary convert ../data` 

Depending on your machine, this can take a long time.
  
### Index the data

First, fire up solr

* `bin/dromedary solr start` 

Then we'll run traject on the configuration in `indexer/main_indexer.rb`

* `bin/dromedary index entries ../data`

### Check it out in the application

* Before restarting the server the first time, you need to migrate your db tables: `bin/rails db:migrate RAILS_ENV=development` then you can fire up the application.
* `bin/rails server`

...and go to http://localhost:3000/  
       
# Other stuff

## Setting up autocomplete for multiple input boxes

The blacklight autocomplete setup is pretty brittle and needs some mucking
about with to get it to work with multiple different input boxes that
target different solr autocomplete endpoints. 

### Catalog controller configuration

You can set up multiple autocomplete configurations by doing the following
(which mirrors the default blacklight configuration)

```ruby
  config.autocomplete = {
       keyword: {
         solr_endpoint: path_to_solr_handler,
         search_component_name: "mySuggester"
       },
       # more configs here
  }

```

`keyword` is the name of the search in the
`config.add_search_field(name, ...)` and allows the search field picker
dropdown to control which configuration is used.


### autocomplete.js

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

### Monkey-patching blacklight

I don't actually moneky-patch, but I do use `Module#prepend`. The code
is in `config/initializers/autcomplete_override_code.rb`
