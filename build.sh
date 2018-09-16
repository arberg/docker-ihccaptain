#!/bin/bash
set -ex

. env.sh

sudo docker build -t $USERNAME/$IMAGE:latest .