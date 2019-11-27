#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

# semver uses a plus character for the build number (if present).
# This is invalid for a Docker tag, so we replace it with a minus.
version=$(./bump_version.sh show|sed "s/+/-/")
docker build -t "$IMAGE_NAME":"$version" .
