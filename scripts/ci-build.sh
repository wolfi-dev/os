#!/usr/bin/env bash

export "date=$(date -u +%Y%m%d)"
export "epoch=$(date -u +%s)"

git config --global --add safe.directory "$GITHUB_WORKSPACE"

make MELANGE="melange" local-melange.rsa

# Setup the melange cache dir on the host so we can use that in subsequent builds
mkdir ../.melangecache
for package in ${PACKAGES}; do
  make MELANGE_EXTRA_OPTS="--create-build-log --cache-dir=$(pwd)/../.melangecache" REPO="${GITHUB_WORKSPACE}/packages" package/"${package}" -j1
  make REPO="${GITHUB_WORKSPACE}/packages" test/"${package}" -j1
done
