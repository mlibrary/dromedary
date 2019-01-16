# Dromedary: Super-fast installation / update

## Make a place to work

* Create a directory to use as a base (mine is at `~/devel/med`). From
here on out, we'll just call it `med`
* `cd med`

## Get the data

* `mkdir data`
* Go to https://umich.app.box.com/folder/48689653172 and get the files `entries.json.gz` and `bib_all.xml`
and put them into the new `data` directory

## Set up the code

Starting from within the `med` directory:

* `git clone git@github.com:mlibrary/dromedary.git`
* `cd dromedary`
* `bundle install --path ./.bundle`

## Set up solr and fire it up

* `bin/dromedary solr install`
* `bin/dromedary solr start`

## Index the data

* `bin/dromedary index all ../data/entries.json.gz ../data/bib_all.xml`

## Update the db and fire up rails

* `bin/rails db:migrate`
* `bin/rails s` # starts the server


## Updatingto and indexing a new version of the data

* Replace `data/entries.json.gz` with the new data file from 
  https://umich.app.box.com/folder/48689653172
* `bin/dromedary index all ../data/entries.json.gz ../data/bib_all.xml`

