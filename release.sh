set -ex

. env.sh

# ensure we're up to date
git pull

./build.sh

# tag it
git add -A
git commit -m "version $VERSION"
git tag -a "$VERSION" -m "version $VERSION"
git push
git push --tags

sudo docker tag $USERNAME/$IMAGE:latest $USERNAME/$IMAGE:$VERSION
# push it
sudo docker push $USERNAME/$IMAGE:latest
sudo docker push $USERNAME/$IMAGE:$VERSION
