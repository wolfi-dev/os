#!/usr/bin/env bash

set -euo pipefail

for p in $(make list); do
  echo "--- package" $p

  if [ -f ${p}.yaml ]; then
    if [ -f **/${p}/${p}.melange.yaml ]; then
      echo "ERROR: ${p}.yaml and **/${p}/${p}.melange.yaml both exist"
      exit 1
    fi

    fn=${p}.yaml
  elif [ -f **/${p}/${p}.melange.yaml ]; then
    fn=$(ls **/${p}/${p}.melange.yaml | head -n 1)
  else
    echo "ERROR: ${p}.yaml or **/${p}/${p}.melange.yaml does not exist, or multiple matches found"
    exit 1
  fi

  # Don't specify repositories or keyring for os packages
  if grep -q packages.wolfi.dev/os ${fn}; then
    yq -i 'del(.environment.contents.repositories)' ${fn}
    yq -i 'del(.environment.contents.keyring)' ${fn}
  fi

  # Don't specify wolfi-base or any of its packages, or the main package, for test pipelines.
  for pkg in wolfi-base busybox apk-tools wolfi-keys ${p}; do
    yq -i 'del(.test.environment.contents.packages[] | select(. == "'${pkg}'"))' ${fn}
    yam ${fn}
  done

  # If .test.environment.contents.packages is empty, remove it all.
  if [ "$(yq -r '.test.environment.contents.packages | length' ${fn})" == "0" ]; then
    yq -i 'del(.test.environment.contents)' ${fn}
    yam ${fn}
  fi
done

# New section to check for .sts.yaml files under ./.github/chainguard/
echo "Checking for .sts.yaml files in ./.github/chainguard/..."
for file in $(find .github/chainguard -type f); do
  if [[ ! $file =~ \.sts\.yaml$ ]]; then
    echo "ERROR: File $file does not have the required '.sts.yaml' suffix"
    exit 1
  fi
done
