#!/bin/sh

set -e

# Set environment variables
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa"
export RESIN_PROJECT=$(echo "$RESIN_REPO" | awk -F '/' '{ print $2 }' | awk -F '.git' '{ print $1 }')

# Login to target registry
docker login "$TARGET_REGISTRY" --username "$TARGET_REGISTRY_USERNAME" --password "$TARGET_REGISTRY_PASSWORD"
docker login "$RESIN_REGISTRY" --username "$RESIN_REGISTRY_USERNAME" --password "$RESIN_API_KEY"

# Prep build dir
rm -rf /build
cp -R /source /build
cd /build

# Login to git
GIT_USERNAME=$(git log --format='%an' HEAD^..HEAD)
GIT_EMAIL=$(git log --format='%ae' HEAD^..HEAD)
git config user.name $GIT_USERNAME
git config user.email $GIT_EMAIL

# Create a new revision, this forces resin.io to do a new build
echo $(git rev-parse HEAD) > .xxx-build-ref
git add .xxx-build-ref
git commit -m 'Updated Build Ref'

git remote add arm-build $RESIN_REPO
git push arm-build $GIT_BRANCH:master -f

# Get the last commit id - this is used as the docker image name at resin.io
COMMIT=$(git rev-parse HEAD)

# Pull the image from resin.io
docker pull registry.resin.io/$RESIN_PROJECT/$COMMIT

# Tag the image
docker tag registry.resin.io/$RESIN_PROJECT/$COMMIT $TARGET_REGISTRY/$TARGET_IMAGE

echo "Pushing new image: $TARGET_IMAGE"

# Push the image to target registry
docker push $TARGET_IMAGE
