# Dromedary -- Middle English Dictionary Application

A new(-ish, these days) discovery system for the Middle English Dictionary.

Confusingly, there are three separate repositories:
 * [dromedary](https://github.com/mlibrary/dromedary), this repo, is the
   **Rails application**. The name was given the project
   when someone decided we should start naming project with nonsense words.
 * [middle_english_dictionary](https://github.com/mlibrary/middle_english_dictionary) is
   not, as one might expect, the Middle English Dictionary code. Instead,
   it's the code that pulls out indexable data from each little 
   XML file, inserts things like links to the OED and DOE, and serves
   as the basis for building solr documents.
 * [middle-english-argocd](https://github.com/mlibrary/middle-english-argocd)(_private_) is the argocd setup which deals with environment
   variables and secrets, and serves to push the application to production. It also
   has a small-but-valid .zip file under the `sample_data` directory.

## Documentation
* [Setting up a development environment](docs/setting_up.md) runs through
  how to get the docker-compose-based dev environment off the ground and
  index some data into its local solr. 
* [Overview of indexing](docs/indexing.md) talks about what the indexing
  process does, where the important files are, and what code might be
  interesting.
* [Configuration](docs/configuration.md) does a _very_ brief run through
  the important ENV values. In general, the [compose.yml](compose.yml) file,
  the argocd repository, and especially [lib/dromedary/services.rb](lib/dromedary/services.rb)
  will be the best place to see what values are available to change. _Don't do that
  unless you know what you're doing, though_.
* [Solr setup](docs/solr_setup.md) looks at the interesting bits of the
  solr configuration, in particular the suggesters (for autocomplete).
* [Tour of the application code](docs/application_code.md) is a quick look at how
  the MED differs from a stock Rails application.
* [Deployment to production](docs/deployment.md) shows the steps for building the 
  correct image and getting it running on the production cluster, as well as
  how to roll back if something went wrong.

### Access links
* **Public-facing application**: https://quod.lib.umich.edu/m/middle-english-dictionary/
* **"Preview" application with exposed Admin panel**: https://preview.med.lib.umich.edu/m/middle-english-dictionary/admin

### About upgrading

This repo currently runs on Ruby 2.x and Blacklight 5.x, and there are no plans
to upgrade either.


<pre>



</pre>

<hr>
<hr>




# OLD STUFF 

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


## Development Quick Start

### SUPER quick start

The steps enumerated and explained below can be run via `bin/setup_dev.sh`.

#### Handy Dandy Aliases (Optional)
```shell
alias dc="docker-compose"
alias dce="dc exec --"
alias abe="dce app bundle exec"
```
### Build application and solr image
The default is **amd64** architecture a.k.a. Intel
```shell
docker-compose build app
docker-compose build solr
```
For Apple Silicon use **arm64** architecture
```shell
docker-compose build --build-arg ARCH=arm64 app
docker-compose build --build-arg ARCH=arm64 solr
```
### Login into docker GitHub packages
```shell
 docker login ghcr.io --username <github-user> --password <personal-access-token>
```
### Bring up development environment
```shell
docker-compose up -d
```


Verify the application is running http://localhost:3000/

## Bring it all down then back up again
```shell
docker-compose down
```
```shell
docker-compose up -d
```

Note that there's no data in it yet, so lots of actions will throw errors. It's time
to index some data.