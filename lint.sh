#!/usr/bin/env bash

set -uo pipefail

for f in *.yaml; do
  echo "---" $f

  # Check that every name-version-epoch is defined in Makefile
  name=$(yq '.package.name' $f)
  version=$(yq '.package.version' $f)
  epoch=$(yq '.package.epoch' $f)
  want="build-package,${name},${version}-r${epoch}"
  if ! grep -q $want Makefile; then
    echo "missing $want in Makefile"
    exit 1
  fi

  # Remove repositories and keys defined in the YAML; these should only be
  # appended at build-time to the local packages.
  yq -i 'del(.environment.contents.repositories)' $f
  yq -i 'del(.environment.contents.keyring)' $f
done
