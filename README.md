# Dromedary -- Middle English Dictionary Application

A new(-ish, these days) discovery system for the Middle English Dictionary.

## Repositories

* **Public Repository for app**: https://github.com/mlibrary/dromedary
* **Private repository for argo build**: https://github.com/mlibrary/middle-english-argocd

If you need access to the private repo, get in touch with A&E.

## Setup your development environment

The development environment is set up to use `docker compose` to manage 
the rails application, solr, and zookeeper (used to manage solr).

To build and start running the application:

```shell
docker compose build
docker compose up -d
```

### Test access to the application and solr

* **Error page**: http://localhost:3000/. Don't let that confuse you.
* **Splash page**: http://localhost:3000/m/middle-english-dictionary.
* **Solr admin**:
  * **url**: http://localhost:9172
  * **username**: solr
  * **password** SolrRocks

**NOTE** At this point you can't do any searches, because there's no data in the
solr yet.


### Indexing a file locally

NOTE: You can't index a file locally through the administration interface -- that's 
hooked directly to an AWS bucket, and won't affect your local install at all
(it'll replace the `preview` solr data).

* Make sure  

```shell
docker compose run app -- bin/index_new_file.rb <path>/<to file>.zip
```

Give it however long it takes (a couple minutes for a minimal file,
and around an hour for a full file). 

You'll know it's done when the 


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
