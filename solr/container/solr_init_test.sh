#!/bin/bash

#this is for running tests in github actions

# enables solr to start with basic auth turned on
solr zk cp /var/solr/data/security.json zk:security.json -z zoo:2181

# runs docker entry-point.sh and whatever is in command
exec /opt/docker-solr/scripts/docker-entrypoint.sh "$@"
