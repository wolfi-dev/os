#!/usr/bin/env bash

set -euo pipefail

makepkgs=$(make list-yaml)
for f in *.yaml; do
  echo "---" $f

  # Check that every name-version-epoch is defined in Makefile
  name=$(yq '.package.name' $f)
  version=$(yq '.package.version' $f)
  epoch=$(yq '.package.epoch' $f)
  if ! echo $makepkgs | grep -wq $f; then
    echo "missing $f in Makefile"
    exit 1
  fi

  # Don't specify packages.wolfi.dev/os as a repository, and remove it from the keyring.
  # Packages from the bootstrap repo should be allowed, but otherwise packages
  # should be fetched locally and the local repository should be appended at
  # build time.
  if grep -q packages.wolfi.dev/os $f; then
    yq -i 'del(.environment.contents.repositories)' $f
    yq -i 'del(.environment.contents.keyring)' $f
  fi
done