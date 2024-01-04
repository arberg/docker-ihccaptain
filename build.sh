#!/bin/bash
. env.sh
if [ ! -z "$1" ] ; then
	VERSION=$1
fi
echo "VERSION=$VERSION"
echo "USERNAME=$USERNAME"
echo "IMAGE=$IMAGE"

set -ex

BASE_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
chmod 755 "$BASE_DIR"/host/*.sh

if [[ "$1" == "--no-cache" ]] ; then
	echo "########### Fresh no-cache build ###########"
	docker build --no-cache --rm -t $USERNAME/$IMAGE:latest .
else
	echo "########### Building using build-cache ###########"
	docker build -t $USERNAME/$IMAGE:latest .
fi


# Copy ihc installer to host, so its easier (for me the developer) to merge new changes to install-script

# rm -r $(dirname "$0")/host/last_install_scripts/$(cat VERSION)*
BACKUP_DIR="/host/previous_installs/$(cat VERSION)"
mkdir -p "$BASE_DIR/host/previous_installs/$(cat VERSION)"
docker run --rm -v $BASE_DIR/host:/host $USERNAME/$IMAGE:latest bash -c "cp -R /opt/ihccaptain/installer $BACKUP_DIR; cp -R /opt/ihccaptain/dataOrg $BACKUP_DIR/data; cp /tmp/install $BACKUP_DIR"
# docker run --rm -v /mnt/user/dockerhub/docker-ihccaptain/host:/host arberg/ihccaptain:latest "cp -r /opt/ihccaptain/installer /host/"
