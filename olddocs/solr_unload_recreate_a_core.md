# Unload/Recreate a solr core

We have to do this sometimes on the servers if something goes wrong with the solr configuration.

Obviously, substitute in the name of the core and/or port as necessary.

```bash

curl "http://localhost:8082/solr/admin/cores?action=UNLOAD&core=dromedary_testing"

curl "http://localhost:8082/solr/admin/cores?action=CREATE&name=dromedary_testing&config=solrconfig.xml&dataDir=data&instanceDir=/var/lib/solr-6.1.0/home/dromedary_testing&wt=json"

```