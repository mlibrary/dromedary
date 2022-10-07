# Setting up MED on Kubernetes

blah

## Solr Operator

For secure, reliable Solr in the kubernetes cluster! Cribbed heavily from [the HathiTrust docs](https://github.com/hathitrust/hathitrust_catalog_indexer/blob/78631a3d0831653f038222b644e6ffc83d5f8294/solr/solrcloud/README.md).

### Set up via Helm
The LIT k8s cluster already has the appropriate Helm charts installed, but you will need to install `helm` on the machine you are using to interact with Kubernetes. (Installing helm charts on minikube is beyond the scope of this documentation.)

From inside the `dromedary` github repository:
```bash
$ helm install middle-english apache-solr/solr \
    --version 0.6 \
    --namespace middle-english-testing \
    -f solr-helm-values.yml
```
(or staging, or production)

You can retrieve the `admin` password that will have been created for you like so:
```bash
kubectl -n middle-english-testing get secret middle-english-solrcloud-security-bootstrap -o jsonpath='{.data.admin}' | base64 -d
```
Depending on your shell and the characters in the password, you may or may not be able to assign this password to a shell variable!

Port-forward to do the next steps, in Lens or in the terminal:
```bash
kubectl -n middle-english-testing port-forward service/middle-english-solrcloud-common 8983:80
```

### Upload the configuration
First, zip up the configuration:
```bash
cd [git repo directory]/solr/med/conf/
zip -r ../../../middle-english.zip .
```

Then upload it:
```bash
curl -u "admin:$SOLR_PASS" -X PUT   --header "Content-Type: application/octet-stream"   \
    --data-binary @middle-english.zip   \
    "http://localhost:8983/api/cluster/configs/middle-english"
```

### Create a collection
Like a core, but cloud-y.
```bash
curl -u "admin:$SOLR_PASS" "http://localhost:8983/solr/admin/collections?action=CREATE&name=middle-english&numShards=1&replicationFactor=3&maxShardsPerNode=2&collection.configName=middle-english"
```