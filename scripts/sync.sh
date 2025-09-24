#!/usr/bin/env bash

set -eou pipefail

grep us-docker main.tf | awk -F'[/:]' '{print $4}' | while read -r IMAGE; do
  docker pull "ghcr.io/lehigh-university-libraries/$IMAGE:main"
  docker tag \
    "ghcr.io/lehigh-university-libraries/$IMAGE:main" \
    "us-docker.pkg.dev/$GOOGLE_CLOUD_PROJECT/shared/$IMAGE:main"
  docker push "us-docker.pkg.dev/$GOOGLE_CLOUD_PROJECT/shared/$IMAGE:main"
done
