# Extracting and converting the data

The data is stored in little `.xml` files. We want to get them from the Box directory,
extract the little XML files from their enclosing `.zip` files, and then convert 
them to a different format (because ruby deals with XML *very* slowly).

## Extract the raw data

  * Go to [the main MED box folder](https://umich.app.box.com/s/ah2imm5webu32to343p2n6xur828zi5w)
   and hit the "Download" button in the upper-right to get a zip file called
   _In_progress_MEC_files.zip_. Pay attention to where it goes -- almost certainly
   `~/Downloads` on a Macintosh.
  * If you used Safari to do the download, it probably unzipped it automatically.
    We want the zip file, so you can right-click on the directory and choose "Compress".
  * `cd` into your `dromedary` directory (where you cloned the app)
  * Pick a place for the data to go. You should probably use a `data` directory
   in the parent directory of your `dromedary` directory (so `../data` from where you are
    now) unless you have a good reason not to.
  * Extract the data to that place: 
    * `bin/dromedary extract /path/to/In_progress_MEC_files.zip ../data`
    
## Convert the little XML files into something faster/better

NOTE: You can skip this conversion step if you just get the already-converted json files
from Bill. The conversion process can take a looooong time.

* `bin/dromedary convert ../data` 

This will look for `../data/xml` and do the conversion, resulting in 
the files: 
* `entries.json.gz` 
* `quotes.json.gz`

The `quotes.json.gz` file is not currently used by the indexing process,
which just pulls the data from the entry itself.

## Clear out/reload solr and index

You should now be ready to (re)index

* `bin/dromedary solr start` # if it's not already running
* `bin/dromedary solr clear`
* `bin/dromedary solr reload`
* `bin/dromedary index entries ../data/entries.json.gz`
