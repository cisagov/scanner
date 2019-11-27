#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

echo "$DOCKER_PW" | docker login -u "$DOCKER_USER" --password-stdin
# semver uses a plus character for the build number (if present).
# This is invalid for a Docker tag, so we replace it with a minus.
version=$(./bump_version.sh show|sed "s/+/-/")
docker push "$IMAGE_NAME":"$version"
