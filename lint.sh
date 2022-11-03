#!/usr/bin/env bash

set -uo pipefail

for f in *.yaml; do
  echo "---" $f
  # Remove repositories and keys defined in the YAML; these should only be
  # appended at build-time to the local packages.
  yq -i 'del(.environment.contents.repositories)' $f
  yq -i 'del(.environment.contents.keyring)' $f
done
