#!/usr/bin/env bash

set -euo pipefail

for fn in *.yaml; do
  p=$(yq -r '.package.name' ${fn})
  echo "--- package" $p

  # Don't specify repositories or keyring for os packages
  if grep -q packages.wolfi.dev/os ${fn}; then
    yq -i 'del(.environment.contents.repositories)' ${fn}
    yq -i 'del(.environment.contents.keyring)' ${fn}
  fi

  # Don't specify wolfi-base or any of its packages, or the main package, for test pipelines.
  for pkg in wolfi-base busybox apk-tools wolfi-keys ${p}; do
    yq -i 'del(.test.environment.contents.packages[] | select(. == "'${pkg}'"))' ${fn}
  done

  # If .test.environment.contents.packages is empty, remove it all.
  if [ "$(yq -r '.test.environment.contents.packages | length' ${fn})" == "0" ]; then
    yq -i 'del(.test.environment.contents)' ${fn}
  fi

  yam ${fn}
done

# New section to check for .sts.yaml files under ./.github/chainguard/
echo "Checking for .sts.yaml files in ./.github/chainguard/..."
for file in $(find .github/chainguard -type f); do
  if [[ ! $file =~ \.sts\.yaml$ ]]; then
    echo "ERROR: File $file does not have the required '.sts.yaml' suffix"
    exit 1
  fi
done
