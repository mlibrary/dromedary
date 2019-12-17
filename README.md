# Dromedary -- Middle English Dictionary Application

A new discovery system for the Middle English Dictionary.

* [Indexing new data](docs/indexing.md), when new data is made available.

For developers:
* [Overview: what can you do with the bin/dromedary helper script?](docs/dromedary_executable.md)
* [Deploying new _code_](docs/deploying.md) for when changes have been made 
to the rails application, or solr config.
* [How to set up autocomplete for multiple search fields](docs/autocomplete_setup.md)
* [Quick and easy(?) instructions](docs/setting_up_dev_environment_on_unix_or_mac.md) for the initial setup

## Setting maintenance mode

Maintenance mode (where folks get a message that the MED is down) happens 
automatically during indexing. If it needs to be set for some other 
reason (e.g., the solr is down or something):

* `ssh deployhost exec dromedary-production "bin/dromedary maintenance_mode on"`
* `ssh deployhost exec dromedary-production "bin/dromedary maintenance_mode off"`
