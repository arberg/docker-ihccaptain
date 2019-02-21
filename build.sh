#!/bin/bash
set -ex

. env.sh

chmod 755 host/*.sh
docker build -t $USERNAME/$IMAGE:latest .