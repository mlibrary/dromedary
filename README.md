# Dromedary -- Middle English Dictionary Application

A new application front-end for the Middle English Dictionary.

## Super-fast installation

### Make a place to work

* Create a directory to use as a base (mine is at `~/devel/med`). From
here on out, we'll just call it `med`
* `cd med`

### Get the data

* `mkdir data`
* Go to https://umich.app.box.com/folder/48689653172 and get the file `entries.json.gz`
and put it into the new `data` directory

### Set up the code

Starting from within the `med` directory:

* `git clone git@github.com:mlibrary/dromedary.git`
* `cd dromedary`
* `bundle install --path ./.bundle`

### Set up solr and fire it up

* `bin/dromedary solr install`
* `bin/dromedary solr start`

### Index the data

* `bin/dromedary index entries ../data/entries.json.gz`

### Update the db and fire up rails

* `bin/rails db:migrate`
* `bin/rails s` # starts the server


## Updatingto and indexing a new version of the data

* Replace `data/entries.json.gz` with the new data file from 
  https://umich.app.box.com/folder/48689653172
* `bin/dromedary solr clear` # delete all the old documents
* `bin/dromedary solr reload` # reload any new solr configuration
* `bin/dromedary index entries ../data/entries.json.gz`

