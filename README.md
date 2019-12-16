# Dromedary -- Middle English Dictionary Application

A new discovery system for the Middle English Dictionary.

* [Quick and easy(?) instructions](docs/setup.md) for the initial setup
* [What can you do with the bin/dromedary helper script?](docs/bin_dromedary.md)
* [How to set up autocomplete for multiple search fields](docs/autocomplete_setup.md)
* [Cheat-sheet for using curl to unload/reload a core](docs/solr_unload_recreate_a_core.md)

## How to update the data once you've installed already

* First, make sure you have the newest code

```bash
cd /path/to/dromedary
git pull origin master
```

* Get the latest data files (`entries.json.gz` and `bib_all.xml`) from [the box directory](https://umich.app.box.com/folder/48689653172)
* Run the indexer

```bash
bin/dromedary index all ../path/to/entries.json.gz ../path/to/bib_all.xml
```

* Wait. And wait some more.

* Done!
