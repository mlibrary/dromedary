# Dromedary -- Middle English Dictionary Application


## Getting set up

There are a lot of moving parts, so let's go through them

### Set up a working direectory

  * Make a directory to hold everything (presumed to be named `med`)
    * `mkdir /some/path/to/med`
    * `cd /some/path/to/med`
    
From here on in we'll call this directory `/some/path/to/med`.

### Install the `dromedary` code
  * Clone the repo 
    * If you have two-factor on github: `git clone git@github.com:mlibrary/dromedary.git`
    * If not: `git clone https://github.com/mlibrary/dromedary`
    * `cd dromedary`
    * `bundle install` 
    
The basic dromedary code is now ready for use.

## Install solr

`dromedary` requires a solr installation to work. It's recommended you install
a version just for this project in you `med` directory

From your `dromedary` directory:

* `bin/dromedary solr install`

    
### Get and convert the raw data

The data is stored in litle `.xml` files. We want to get them from the Box directory,
extract the little XML files from their enclosing `.zip` files, and then convert 
them to a different format (because ruby deals with XML *very* slowly).

  * Go to [the box folder](https://umich.app.box.com/s/ah2imm5webu32to343p2n6xur828zi5w)
   and hit the "Download" button in the upper-right to get a zip file called
   _In_progress_MEC_files_. Pay attention to where it goes -- almost certainly
   `~/Downloads` on a Macintosh.
  * `cd` into your `dromedary` directory
  * Pick a place for the data to go. You should probably use `/some/path/to/med/data`
    (the parent directory of your `dromedary` directory, so `../data` from where you are
    now) unless you have a good reason not to.
  * Extract the data: 
    * `bin/dromedary extract /path/to/In_progress_MEC_files.zip ../data`
  * Do the conversion
    * `bin/dromedary convert ../data` 
    * Depending on your machine, this can take a long time.
  
### Index the data

We'll fire up solr and index the data according to the method in 
`indexer/index.rb`

* `bin/dromedary solr start` 
* `indexer/index.rb ../data/all_entries.marshal`

### Check it out in the application

* `bin/rails server`

...and go to http://localhost:3000/  
       
