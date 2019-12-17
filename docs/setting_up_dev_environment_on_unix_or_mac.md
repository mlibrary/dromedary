# Setting up a Dromedary Development Environment

...on a unix-like (linux or macintosh)

Dromedary has three basic parts:

* The custom code, meaning 
  * the dromedary application (this repository) -- the rails application
  * the middle_english_dictionary gem -- code to pull data out of the 
    XML files and turn it into useful ruby objects used by dromedary.
* The data, which includes:
  * the entries as individual XML files, which has entry and quote information
  * the file `bib_all.xml` which holds all the bib information
  * a `MED2OED_links.<YYYYMM>` mapping MED entries to OED entries (where `YYYYMM`
    is the year/month of its creation)
  *  a `MED2DOE_links.<YYYYMM>` mapping MED entries to DOE entries (where `YYYYMM`
        is the year/month of its creation)
* A solr installation


## 1. Setting up the application

We assume you have `git`, `ruby`, and `java` set up. If you don't, and you're
not sure how to proceed, find someone to help. Everyone at the library is 
very friendly :-)

```bash
# Choose a place to put everything
export MEDDIR=~/devel/med

# Make the directory if it doesn't exist and go there
mkdir -p $MEDDIR
MEDDIR=$(cd $MEDDIR; pwd) # make it absolute
cd $MEDDIR


# Clone the repository and get the gems
# You must be on the lit network (via being at the office
# or using the VPN) for the bundle install to work.

git clone git@github.com:mlibrary/dromedary.git
cd $MEDDIR/dromedary
bundle install --path=.bundle

# IF you need to mess with the middle_english_dictionary gem
# because the structure of the XML files has changed,
# get it, too.

# (only if you need it)
# git clone git@github.com:mlibrary/middle_english_dictionary.git

```

You now have the custom code, templates, etc. we use in the application.

## 2. Setting up solr

Unfortunately, there's no magic link that will get you the latest version of
solr.  You'll have to go to [the solr download page](http://lucene.apache.org/solr/downloads.html)
to get a link to a solr `.tgz` distribution. We target at least solr 6.6.5.

```bash
export SOLR_URL=http://archive.apache.org/dist/lucene/solr/6.6.5/solr-6.6.5.tgz

cd $MEDDIR
curl $SOLR_URL | tar xzf -

# This will create a directory called, e.g., 'solr-6.6.5'. Create a 
# symlink so we can find it more easily as $MEDDIR/solr

ln -s $MEDDIR/solr-6.6.5 $MEDDIR/solr

```

Finally, make a directory in which to keep the data

```bash
mkdir -p $MEDDIR/data
```

You should now have a directory struture of the form:
```ruby
med
 - data
 - dromedary
 - solr # symlink to below
 - solr-X.Y.Z
```

## 3. Making a local index in your local solr

### a. Settings

First, you'll need to create `config/local.settings.yml`. Obviously,
change the `/Users/dueberb/devel/med` bit to point to your own 
med directory.

```yaml
data_dir: /Users/dueberb/devel/med/data
build_dir: /Users/dueberb/devel/med/data/build

blacklight:
  url: http://localhost:9639/solr/med

```

The `blacklight.url` will be used to start/stop/reload the med core.

### b. Fire up solr and load the core for the first time

Starting solr is easy: `bin/dromedary solr start`

Loading the core is more annoying for now

```
cd solr/med
curl "http://localhost:9639/solr/admin/cores?action=CREATE&name=med&config=solrconfig.xml&dataDir=data&instanceDir=$(pwd)&wt=json"
```

If you accidentally left a `core.properties` file laying around, it'll tell you that the core already
exists, even if it isn't currently loaded. You can just run the curl command again.

### c. Index the data for the first time

First, get the `In_progress_MEC_files.zip` file as showing in [the indexing document](indexing.md). 
Assuming you get it downloaded into ~/Downloads, you can:

`bin/dromedary newdata prepare ~/DownloadsIn_progress_MEC_files.zip`
`bin/dromedary newdata index`

The former pre-processes the data into `../data/build`, the other
actually copies it to the real data dir and indexes it to solr.

### d. Fire up the server and take it for a ride!

`bundle exec puma`


