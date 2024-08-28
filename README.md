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
NOTES
* The ***sidekiq*** container will exit because we have yet to do a ***bundle install!***.
> ### Install bundler
> ```shell
> docker-compose exec -- gem install 'bundler:~>2.2.21'
> RUN bundle config --local build.sassc --disable-march-tune-native
> ```
> This was moved into the Dockerfile so it is no longer is necessary but is left here as a reminder so it will not be forgotten.
>
> Need to revisit why setting the bundler version is necessary in the first place!
### Configure bundler
```shell
docker-compose exec -- app bundle config set rubygems.pkg.github.com <personal-access-token>
```
The above command creates the following file: ./bundle/config
```yaml
---
BUNDLE_RUBYGEMS__PKG__GITHUB__COM: "<personal-access-token>"
```
NOTES
* [Personal access tokens (classic)](https://github.com/settings/tokens) Token you have generated that can be used to access the [GitHub API](https://docs.github.com/en) -- read:packages.
* Replace <personal-access-token> with your personal access token.

### Bundle install
```shell
docker-compose exec -- app bundle install
```
NOTES
* Environment variable **BUNDLE_PATH** is set to **/var/opt/app/gems** in the **Dockerfile**.
### Yarn install
```shell
docker-compose exec -- app yarn install
```
NOTES
* Investigate using a volume for **node_modules** directory like we do for **gems**
### Setup databases
```shell
docker-compose exec -- app bundle exec rails db:setup
```
If you need to recreate the databases run db:drop and then db:setup.
```shell
docker-compose exec -- app bundle exec rails db:drop
docker-compose exec -- app bundle exec rails db:setup
```
NOTES
* Names of the databases are defined in **./config/database.yml**
* The environment variable **DATABASE_URL** takes precedence over configured values.
### Create solr collections
```shell
docker-compose exec -- solr solr create_collection -d dromedary -c dromedary-development 
docker-compose exec -- solr solr create_collection -d dromedary -c dromedary-test 
```
If you need to recreate a core run delete and create_core (e.g. dromedary-test)
```shell
docker-compose exec -- solr solr delete -c dromedary-test
docker-compose exec -- solr solr create_collection -d dromedary -c dromedary-test 
```
NOTES
* Names of the solr cores are defined in **./config/blacklight.yml** file.
* The environment variable **SOLR_URL** takes precedence over configured values.
### Start development rails server
```shell
docker-compose exec -- app bundle exec rails s -b 0.0.0.0
```
Verify the application is running http://localhost:3000/
## Bring it all down then back up again
```shell
docker-compose down
```
```shell
docker-compose up -d
```
```shell
docker-compose exec -- app bundle exec rails s -b 0.0.0.0
```
The gems, database, and solr redis use volumes to persit between the ups and downs of development.
When things get flakey you have the option to simply delete any or all volumes after you bring it all down.
If you remove all volumes just repeat the [Development quick start](#development-quick-start), otherwise
you'll need to run the appropriate steps depending on which volumes you deleted:
* For gems run the [Bundle install](#bundle-install) step.
* For database run the [Setup databases](#setup-databases) step.
* For solr run the [Create solr collections](#create-solr-collections) step.
