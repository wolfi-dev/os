#!/usr/bin/env bash

set -euo pipefail

makepkgs=$(make list-yaml)
for f in *.yaml; do
  echo "---" $f

  # Don't specify packages.wolfi.dev/os as a repository, and remove it from the keyring.
  # Packages from the bootstrap repo should be allowed, but otherwise packages
  # should be fetched locally and the local repository should be appended at
  # build time.
  if grep -q packages.wolfi.dev/os $f; then
    yq -i 'del(.environment.contents.repositories)' $f
    yq -i 'del(.environment.contents.keyring)' $f
  fi

  # With the introduction of https://github.com/wolfi-dev/advisories,
  # package config files should no longer contain any advisory data.
  if [[ "$(yq 'keys | contains(["advisories"])' "$f")" == "true" ]]; then
    echo "
$f has an 'advisories' section, but advisory data should now be stored in https://github.com/wolfi-dev/advisories.

To learn about how to create advisory data in the advisories repo, run 'wolfictl advisory create -h', and check out the '--advisories-repo-dir' flag."
    exit 1
  fi
done
