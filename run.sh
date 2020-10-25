#!/usr/bin/env bash
CURRENT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
HOST_PORT=8100
HOST_SSLPORT=9100
DOCKER_NAME=IHCCaptain
if [[ "$1" == "" ]] ; then
	IMAGE=arberg/ihccaptain:latest
else
	IMAGE=$1
fi
echo "Using image: $IMAGE"
echo "Stopping old if exists"
docker stop $DOCKER_NAME
echo "Removing old if exists"
docker rm $DOCKER_NAME
echo "Running: $IMAGE"
# /etc/timezone:ro is a file in the docker but a directory locally on my system

set -ex
docker run -d --name $DOCKER_NAME -p $HOST_PORT:80 -p $HOST_SSLPORT:443 -v $CURRENT_DIR/data:/opt/ihccaptain/data/ -v $CURRENT_DIR/host:/host/ -v "/etc/localtime:/etc/localtime:ro" $IMAGE