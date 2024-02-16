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
done
