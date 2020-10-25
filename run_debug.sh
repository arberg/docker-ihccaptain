#!/usr/bin/env bash
CURRENT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
HOST_PORT=8100
HOST_SSLPORT=9100
DOCKER_NAME=IHCCaptain
if [[ "$1" == "" ]] ; then
	IMAGE=arberg/ihccaptain:auto
else
	IMAGE=$1
fi
echo "Using image: $IMAGE"
echo "Stopping old if exists"
docker stop $DOCKER_NAME

set -ex
docker run -it --rm --name ${DOCKER_NAME}_debug -p $HOST_PORT:80 -p $HOST_SSLPORT:443 -v $CURRENT_DIR/data:/opt/ihccaptain/data/ -v $CURRENT_DIR/host:/host/ -v "/etc/localtime:/etc/localtime:ro" $IMAGE bash