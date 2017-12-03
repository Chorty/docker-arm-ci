#!/bin/sh

set -e

# Save resin ssh key
mkdir -p ~/.ssh && echo "$RESIN_PRIVATE_KEY" > ~/.ssh/id_rsa && chmod 400 ~/.ssh/id_rsa

# Set environment variables
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa"
export RESIN_PROJECT=$(echo "$RESIN_REPO" | awk -F '/' '{ print $2 }' | awk -F '.git' '{ print $1 }')
export BRANCH=$(if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then echo $TRAVIS_BRANCH; else echo $TRAVIS_PULL_REQUEST_BRANCH; fi)

echo "TRAVIS_BRANCH=$TRAVIS_BRANCH, PR=$PR, BRANCH=$BRANCH"

# Login to docker registry
docker login --username "$DOCKER_USERNAME" --password "$DOCKER_PASSWORD"
docker login "$RESIN_REGISTRY" --username "$RESIN_USERNAME" --password "$RESIN_API_KEY"

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
git checkout $BRANCH
echo $(git rev-parse HEAD) > .xxx-build-ref
git add .xxx-build-ref
git commit -m 'Updated Build Ref'

git remote add arm-build $RESIN_REPO
git push arm-build $BRANCH:master -f

# Get the last commit id - this is used as the docker image name at resin.io
COMMIT=$(git rev-parse HEAD)

# Pull the image from resin.io
docker pull registry.resin.io/$RESIN_PROJECT/$COMMIT

# Tag the image
docker tag registry.resin.io/$RESIN_PROJECT/$COMMIT $TARGET_IMAGE:$TARGET_IMAGE_TAG

# Push the image to target registry
echo "Publishing image: $TARGET_IMAGE:$TARGET_IMAGE_TAG"
docker push $TARGET_IMAGE:$TARGET_IMAGE_TAG
