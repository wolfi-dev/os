#!/usr/bin/env bash

set -euo pipefail

for f in *.yaml; do
  echo "---" $f
  name=$(grep "^  name: [a-z0-9-]*" $f | cut -d' ' -f4)
  version=$(grep "^  version: [a-z0-9-]*" $f | cut -d' ' -f4)
  epoch=$(grep "^  epoch: [0-9]*" $f | cut -d' ' -f4)

  want="build-package,$name,$version-r$epoch"
  if ! grep -q "$want" Makefile; then
    echo "$want" not found in Makefile
    exit 1
  fi
done
