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
	IHCCAPTAIN_IMAGE="$USERNAME/$IMAGE:latest" docker compose build --no-cache ihccaptain
else
	echo "########### Building using build-cache ###########"
	IHCCAPTAIN_IMAGE="$USERNAME/$IMAGE:latest" docker compose build ihccaptain
fi


# Copy ihc installer to host, so its easier (for me the developer) to merge new changes to install-script

# rm -r $(dirname "$0")/host/last_install_scripts/$(cat VERSION)*
BACKUP_DIR="/host/previous_installs/$(cat VERSION)"
mkdir -p "$BASE_DIR/host/previous_installs/$(cat VERSION)"
IHCCAPTAIN_IMAGE="$USERNAME/$IMAGE:latest" \
IHCCAPTAIN_HOST_DIR="$BASE_DIR/host" \
  docker compose run --rm --no-deps ihccaptain \
  bash -c "cp -R /opt/ihccaptain/installer $BACKUP_DIR; cp -R /opt/ihccaptain/dataOrg $BACKUP_DIR/data; cp /tmp/install $BACKUP_DIR"
# docker run --rm -v /mnt/user/dockerhub/docker-ihccaptain/host:/host arberg/ihccaptain:latest "cp -r /opt/ihccaptain/installer /host/"
