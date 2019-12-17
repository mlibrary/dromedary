# The `bin/dromedary` helper script

The dromedary source has a script in `bin/dromedary` that can be used
for all sorts of things by developers.

Just running `bin/dromedary` gives you a list of the top-level commands, 
and running `bin/dromedary subcommand -h` will show you _that_ level
of commands. 

There are only a few that are useful -- most of the rest are used to build
up these.

## NOTE: REMOTE EXEC 

Any `bin/dromedary` command can be run on one of the installed
instances with the format:

`bin/dromedary remote <branch> "<command in double quotes>"`. 

So, for example, to reload a solr core on staging, I'd do

`bin/dromedary remote staging "solr reload"` 

This constructs an ssh string that calls through deployhost.

## Deploying the code

_Time to run_: 10mn? But doesn't matter much because nothing switches over 
until the whole deploy is done.

* `bin/dromedary deploy [staging|training|production] [branch]` Runs a deploy. Exactly 
the same as using the ssh command.

Note that if the solr config has changed, you'll also want to reload the core:

* `bin/dromedary remote <staging|training|production> "solr reload"`

## Maintenance mode

_Time to run_: Nothingish.

* `bin/dromedary maintenance_mode on`
* `bin/dromedary maintenance_mode off`

## Index and such

_Time to run_: An hour or more for the prepare step; about half an hour
for the reindex.

* `bin/dromedary newdata prepare <zipfile>` Extract data from the zipfile
into the build directory and convert to files needed for indexing.
* `bin/dromedary newdata index`. Index files from the build directory
into solr.

There are also finer-grained versions of these

* `bin/dromedary extract <zipfile> <datadir>` Extract from the zipfile into the data dir
* `bin/dromedary convert <datadir>` Convert raw xml to files we actually use
* `bin/dromedary index copy_from_build` Copy built files from build dir to data dir for indexing
* `bin/dromedary index entries` Index just the entries from `#{data_dir}/`.
* `bin/dromedary index bib` Index just the biblio stuff
* `bin/dromedary index full` Index both entries and bib with one command and then rebuild the suggesters.
* `bin/dromedary index hyp_to_bibid`. Create the mapping from HYP ids (RID) to bib IDs


## Solr

_Time to run_: Totally depends on the state of the index. 
The `reload` is instantaneous, though, which is nice.

All these will give more information if called with `-h`.
```bash
> bin/dromedary solr -h

Commands:
  dromedary solr commit                # Force solr to commit
  dromedary solr empty                 # Delete all documents in the solr
  dromedary solr install               # Download and install solr to the given directory
  dromedary solr optimize              # Optimize solr index
  dromedary solr rebuild_suggesters    # Tell solr to rebuild all the suggester indexes
  dromedary solr reload                # Tell solr to reload the solr config without restarting
  dromedary solr shell                 # Get a shell connected to solr, optionally with collections
  dromedary solr start [RAILS_ENV]     # Start the solr referenced in .solr
  dromedary solr stop [RAILS_ENV]      # ...or stop it
  dromedary solr up                    # Check to see if solr is up

```
