set -ex

. env.sh

# ensure we're up to date
git pull

./build.sh

# tag it
TAG="$VERSION"
git add -A
git diff-index --quiet HEAD || git commit -m "version $VERSION"
git diff --quiet HEAD "$TAG" || git tag -a "$TAG" -m "version $VERSION"
git push
git push --tags

docker tag $USERNAME/$IMAGE:latest $USERNAME/$IMAGE:$VERSION
# push it
docker push $USERNAME/$IMAGE:latest
docker push $USERNAME/$IMAGE:$VERSION
