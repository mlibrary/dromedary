# What does bin/dromedary do?

## Solr


### Overview
```bash
bin/dromedary solr -h

Commands:
  dromedary solr commit                # Force solr to commit
  dromedary solr empty                 # Delete all documents in the solr
  dromedary solr install               # Download and install solr to the given directory
  dromedary solr link                  # Link in the MED solr configurations to the solr in .solr
  dromedary solr optimize              # Optimize solr index
  dromedary solr rebuild_suggesters    # Tell solr to rebuild all the suggester indexes
  dromedary solr reload                # Tell solr to reload the solr config without restarting
  dromedary solr shell                 # Get a shell connected to solr, optionally with collections
  dromedary solr start [RAILS_ENV]     # Start the solr referenced in .solr
  dromedary solr stop [RAILS_ENV]      # ...or stop it
  dromedary solr up                    # Check to see if solr is up

```

In all cases, the url/port info for solr are taken from `blacklight.yml`

### Installation and control

* `solr install /path/to/dir/for/solr` will install solr 6.x
* `solr start`, `stop`, `commit`, and `optimize` all do what you'd think
* `solr up` will let you know if solr is running

### Resets

* `solr empty` will delete all documents from the solr index
* `solr reload` will reload the solr configuration without you having to shut down solr
* `solr rebuild-suggesters` will rebuild the suggest indexes for autocomplete

### Debugging help

* `solr shell` will dump you into a pry session with `core` already initialized as a 
[SimpleSolrClient::Client](https://github.com/billdueber/simple_solr_client/) instance.


## Indexing data

* `index bib /path/to/bib_all.xml` will index the bib entries (fast)
* `index entries /path/to/entries.json.gz /path/to/bib_all.xml` will index the entries and quotes (slow)
* `index all /path/to/entries.json.gz /path/to/bib_all.xml` will clear the solr index
and then index entries, quotes, and bibs
