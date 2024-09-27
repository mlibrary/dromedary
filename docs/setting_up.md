# Setting up a development environment

The development environment is set up to use `docker compose` to manage
the rails application, solr, and zookeeper (which is used to manage solr).

## Requirements

You'll need docker and docker-compose ready to run. Everything else should be
taken care of inside the containers. 

To build and start running the application:

```shell
docker compose build
docker compose up -d
```

## Test access to the application and solr

* **Not the home page**: http://localhost:3000/. Don't let that confuse you.
* **Actual home page**: http://localhost:3000/m/middle-english-dictionary.
* **MED admin** http://localhost:3000/m/middle-english-dictionary/admin
* **Solr admin**:
  * **url**: http://localhost:9172 # You can change the port in the `compose.yml` file.
  * **username**: solr
  * **password** SolrRocks

**NOTE** At this point you can't do any searches, because there's no data in the
solr yet.


### Indexing a file locally

NOTE: You _can't index a file locally through the administration interface_ -- that's 
hooked directly to an AWS bucket, and won't affect your local install at all
(it'll replace the `med-preview` solr data in the production environment!).

There is a very small file, useful for development,
in the private [middle-english-argocd](https://github.com/mlibrary/middle-english-argocd)
repository at `sample_data/MED_A_SMALL.zip`. It has about 150 records, up through a bunch
of the ones that start with `ab`, which is enough to test indexing, typeahead, and
searching.

```shell
docker compose run app -- bin/index_new_file.rb data/MED_A_SMALL.zip
```

Give it however long it takes (a few minutes for the minimal file,
and up to an hour for a full file). 

You'll know it's done when the [admin page](http://localhost:3000/m/middle-english-dictionary/admin)
shows that the new collection is set and is aliased by `med-preview` or, of course,
by watching the logs scroll by.


### Test the full application

At this point, you should have working typeahead (well, for a few words that start with _ab_)
and search capabilities. 


## Working on the application

NOTE that the solr is not set up to be durable (e.g., every time you bring down solr,
the data is lost). If you're just working on the app, you can bring just the app
container up and down by itself, and leave solr/zookeeper running so as to not lose the index.

```shell
docker compose down app
docker compose up app
```