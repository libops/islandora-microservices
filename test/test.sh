#!/usr/bin/env bash

set -eou pipefail

hash() {
  if command -v md5sum >/dev/null 2>&1; then
    md5sum "$@"
  else
    md5 "$@"
  fi
}

terraform output -json | jq .urls.value > output.json
KEYS=$(jq -r 'keys[]' output.json)
for KEY in $KEYS; do
  URL=$(jq -r ".[\"$KEY\"]" output.json)
  echo "Testing $KEY at $URL"

  if [ "$KEY" == "crayfits" ]; then
    curl -s -o fits.xml \
        --header "Accept: application/xml" \
        --header "Apix-Ldp-Resource: https://www.libops.io/themes/custom/libops_www/assets/img/200x200/islandora.png" \
        "$URL"
    # check the md5 of that file exists in the FITS XML
    grep d6c508e600dcd72d86b599b3afa06ec2 fits.xml | grep md5checksum
    rm fits.xml
  elif [ "$KEY" == "homarus" ]; then
    curl -s -o image.jpg \
        --header "Accept: image/jpeg" \
        --header "Content-Type: video/mp4" \
        --data-binary "@./fixtures/ForBiggerBlazes.mp4" \
        "$URL"
    md5sum image.jpg | grep f489e9e1099237f3fdc88b2b9f65505f
    rm image.jpg

    curl -s -o output.mp4 \
        --header "Accept: video/mp4" \
        --header "Content-Type: video/mp4" \
        --data-binary "@./fixtures/ForBiggerBlazes.mp4" \
        "$URL"
    md5sum output.mp4 | grep 0bcec3106c561980923bceb595bcf686
    rm output.mp4

  elif [ "$KEY" == "houdini" ]; then
    curl -s -o image.png \
        --header "Accept: image/png" \
        --header "Apix-Ldp-Resource: https://www.libops.io/themes/custom/libops_www/assets/img/200x200/islandora.png" \
        "$URL"
    file image.png | grep PNG
    rm image.png
  elif [ "$KEY" == "hypercube" ]; then
    curl -s -o ocr.txt \
        --header "Accept: text/plain" \
        --header "Apix-Ldp-Resource: https://www.libops.io/sites/default/files/2024-05/Screen%20Shot%20on%202024-05-21%20at%2002-32-42.png" \
        "$URL"
    grep healthcheck ocr.txt
    rm ocr.txt
  else
    echo "Unknown service"
    exit 1
  fi
done
rm output.json
