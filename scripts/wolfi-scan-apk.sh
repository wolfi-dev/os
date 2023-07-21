#!/usr/bin/env bash

# THIS SCRIPT IS EXPERIMENTAL!

set -eo pipefail

# Make sure Wolfictl is installed.

if ! command -v wolfictl > /dev/null; then
  echo "This script requires Wolfictl to be installed. To install Wolfictl, check out https://github.com/wolfi-dev/wolfictl"
  exit 1
fi

set -u

while IFS="|" read -r arch _ package version; do
  apk_file="packages/${arch}/${package}-${version}.apk"
  if [[ -f "$apk_file" ]]; then
    echo "Processing ${apk_file}"
    wolfictl scan "$apk_file" --require-zero
  else
    echo "File ${apk_file} not found."
  fi
done < "packages.log"