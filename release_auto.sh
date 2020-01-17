#!/bin/bash
set -ex

# ensure we're up to date
#git pull

# Builds one with wrong VERSION file inside docker, but it matters little. Because the static VERSION file isn't updated based on version being installed from current IHC Captain
./build.sh
. env.sh
VERSION=auto

docker tag $USERNAME/$IMAGE:latest $USERNAME/$IMAGE:$VERSION
# push it
docker push $USERNAME/$IMAGE:latest
docker push $USERNAME/$IMAGE:$VERSION