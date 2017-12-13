#!/bin/sh

# start docker in docker
dockerd >/dev/null 2>&1 &

until docker info >/dev/null 2>&1; do
    echo "Waiting for docker to be available..."
    sleep 1
done

set -e

# Save resin ssh key
mkdir -p ~/.ssh && echo "$RESIN_PRIVATE_KEY" | base64 -d > ~/.ssh/resin && chmod 400 ~/.ssh/resin

# Set environment variables
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/resin"
export RESIN_PROJECT=$(echo "$RESIN_REPO" | awk -F '/' '{ print $2 }' | awk -F '.git' '{ print $1 }')

# Login to docker registry
docker login --username "$DOCKER_USERNAME" --password "$DOCKER_PASSWORD"
docker login "$RESIN_REGISTRY" --username "$RESIN_USERNAME" --password "$RESIN_API_KEY"

# Prep build dir
rm -rf /build
cp -R /source /build
cd /build

# Login to git
git config user.name travis
git config user.email travis@example.com

# Create a new revision, this forces resin.io to do a new build
echo $(git rev-parse HEAD) > .xxx-build-ref
git add .xxx-build-ref
git commit -m 'Updated Build Ref'

git remote add arm-build $RESIN_REPO
git push arm-build $TRAVIS_BRANCH:master -f

# Get the last commit id - this is used as the docker image name at resin.io
COMMIT=$(curl -s -H "Content-Type: application/json" \
    "https://api.resin.io/v1/application?\$filter=app_name%20eq%20'$RESIN_PROJECT'&apikey=$RESIN_API_KEY" | jq -r '.d[0].commit')

# Check to see if we need to push the image to Docker Hub
if [ "$TARGET_IMAGE_TAG" = "" ] || [ -z "$TARGET_IMAGE_TAG" ]; then
    echo "Not pushing image to Docker Hub"
    exit 0
fi

# Pull the image from resin.io
docker pull registry.resin.io/$RESIN_PROJECT/$COMMIT

# Tag the image
docker tag registry.resin.io/$RESIN_PROJECT/$COMMIT $TARGET_IMAGE:$TARGET_IMAGE_TAG

# Push the image to target registry
echo "Publishing image: $TARGET_IMAGE:$TARGET_IMAGE_TAG"
docker push $TARGET_IMAGE:$TARGET_IMAGE_TAG
