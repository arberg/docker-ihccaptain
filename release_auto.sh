#!/bin/bash
# ensure we're up to date
#git pull

# Builds one with wrong VERSION file inside docker, but it matters little. Because the static VERSION file isn't updated based on version being installed from current IHC Captain
AUTO_BUILD_VERSION="auto"
./build.sh "$AUTO_BUILD_VERSION"

. env.sh
VERSION="$AUTO_BUILD_VERSION"

set -ex

docker tag $USERNAME/$IMAGE:latest $USERNAME/$IMAGE:$VERSION
# push it
docker push $USERNAME/$IMAGE:latest
docker push $USERNAME/$IMAGE:$VERSION