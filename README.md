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


### Access links
* **Public-facing application**: https://quod.lib.umich.edu/m/middle-english-dictionary/
* **"Preview" application with exposed Admin panel**: https://preview.med.lib.umich.edu/m/middle-english-dictionary/admin

### About upgrading

This repo currently runs on Ruby 2.x and Blacklight 5.x, and there are no plans
to upgrade either.

```shell
docker-compose up -d
```

Note that there's no data in it yet, so lots of actions will throw errors. It's time
to index some data.
