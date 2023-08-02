#!/bin/bash

arch=$1

if [[ "$1" == "arm64" ]]; then
  buildarg=""
  echo "Using default build architecture"
else
  buildarg="--build-arg ARCH=arm64"
  echo "Building for arm64"
fi

docker-compose down
docker-compose pull --ignore-buildable
docker-compose build "$buildarg"
docker-compose up -d
docker-compose exec app bundle install
docker-compose exec test bundle install
docker-compose exec app yarn install
docker-compose exec app bundle exec rails db:setup
docker-compose exec solr solr create_collection -d med -c dromedary-development
docker-compose exec solr solr create_collection -d med -c dromedary-test
docker-compose exec app bundle exec rails s -b 0.0.0.0
