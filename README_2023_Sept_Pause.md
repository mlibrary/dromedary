# End of 2023-Sept Status

Changes based on Greg's last work:

## What's working

tl;dr -- all the basic functionality can now be run in a containerized environment

* CLI can be used to unzip, prepare, and index data
  * Commands now take command-line arguments to set build directory 
  * TODO: Allow the system to be given only a build root directory and then
    make up a build directory name and use it throughout
  * TODO: Stop pretending we're going to run all this stuff from the command-line and
    make a slightly nicer mechanism for calling it from within the code
* Solr is now running with basic auth (as it will in the cluster)
* Application runs as per normal
* Severely pared down CLI commands to focus only on the indexing process
* Roughly everything can be driven with environment variables

## What needs to happen still (in large strokes)

None of these things seem onerous, but there's a good-sized handful of them. 

* Figure out mounting directories to support indexing
* Set up a convention for determining if the solr/data configuration has changed, so
  we know when to upload a new configuration set to solr and use it when creating
  a new collection to index into
* Build out the solr client to support using solr APIs to create configurations
  and collections (including zipping up the solr configuration in `solr/med`)
* Pull in the code (which is written but not merged in) to allow upload of a new data .zip file
* Take all the CLI stuff and package it up into code that can be called from
  an administrative interface
* Once a new build has been indexed, reload all the necessary stuff and redefine the solr
  target so the new indexes can be verified/tested. 
* Once the testing is done, switch the solr collection alias to point to the new data
  and force all the pods to restart
* Replace the SOLR_USERNAME/SOLR_PASSWORD environment variables with k8s secrets, however
  that works. 
* Set up a more robust testing infrastructure and some more tests


## Basic tooling changes

* Use not-EOL version of node (v16.x)
* Automatically run `bundle install` on launch
* Deprecate copying solr configurations to the solr container; plan is to
  produce a .zip file and send it to solr using the solr Configuration API. This
  should also allow us to use a stock Solr docker image
* Remove references to `redis`/`sidekiq`, which aren't being used (at least for now)
* Pull out `ActionCable`, which we're not using
* Solr now runs with basic auth enabled

## Major change: Configuration via ENV variables and Service object

Synopsis:
  * All configuration is controlled by environment variables and sane defaults
  * All configuration is accessed in the code via `Dromedary::Services` (a `Cannister`)
    * TODO: Fully rip out all the (now dead-code) stuff that used `Ettin`
  * Configuration now separates out locations for "live" data, build locations,
    and allows more granular specification of the Solr endpoints

Dromedary needs (depending on the use) configuration that goes beyond what one can
usefully do in a YAML file. 

To deal with this, a `cannister` object at `Dromedary::Services` is the one, central
location for configuration data. Everything else has been changed to call this, 
directly or indirectly, including the YAML files (which are run through ERB first)
and the routes. 

### ENVIRONMENT Variables used for configuration

Looking at the `docker-compose.yml` and `lib/dromedary/services.rb` should, at a glance,
give a good idea of how things are working. Here's what we're using now.

* DATA_ROOT (optional): A convenient starting place for data. Defaults for LIVE_DATA_DIRECTORY and BUILD_DIRECTORY
  are based off this.
* LIVE_DATA_DIRECTORY: Where the "live" version of `hyp_to_bibid.json` lives, used when running the app
* BUILD_ROOT: Directory under which versioned (dated?) builds take place.
  * If indexing new data, we need a spot to unzip and process it. If BUILD_ROOT is defined, we can derive
    a BUILD_DIRECTORY is not set directly.
* BUILD_DIRECTORY: The target for unzipping and processing new data. It will contain the `xml/` directory
  and (after processing) the `entries.json.gz` and `hyp_to_bibid.json` files for that build. Can also
  be specified on the command line for most CLI operations.
  * Default is `BUILD_ROOT/build_YYYYMMDD`
  * Note that at least one of BUILD_ROOT and BUILD_DIRECTORY must be set for an indexing operation
* SOLR_ROOT: The "base" url for the solr install (e.g., http://solr/solr)
* SOLR_COLLECTION: The collection name; combined with SOLR_ROOT to get a complete URL
  * TODO: Generate a new collection when doing an indexing job, creating it as part of the indexing process
  * TODO?: Separate configs for live/reindex solr targets???
* SOLR_USERNAME / SOLR_PASSWORD: For logging into solr using basic auth
