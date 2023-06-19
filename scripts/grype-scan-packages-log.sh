#!/usr/bin/env bash

# THIS SCRIPT IS EXPERIMENTAL!

# IMPORTANT: One unfortunate trait of this script is that, by necessity (for
# now), it uses what Grype calls "directory scanning catalogers" and not "image
# scanning catalogers" (for more information on the difference, see
# https://github.com/anchore/syft/#default-cataloger-configuration-by-scan-type).
# The latter is desirable here, since it equates to scanning software that is
# determined to be installed rather than merely referenced (e.g a test
# dependency mentioned in a lockfile). The Grype team is aware of the need to
# make it easier to scan 'installed' software in directory scans (see
# https://github.com/anchore/syft/issues/1039), and we can improve this script
# when that functionality is added.

set -eo pipefail

# Make sure Grype is installed.

if ! command -v grype > /dev/null; then
  echo "This script requires Grype to be installed. To install Grype, check out https://github.com/anchore/grype#installation."
  exit 1
fi

# Check if packages.log file exists

if [[ ! -f "packages.log" ]]; then
  echo "Cannot find packages.log file.  No apks to scan."
  exit 0
fi

# Optionally let the user pass in a Grype output flag argument.

output_flag=""

if [[ ${#1} -gt 0 ]]; then
  output_flag="-o ${1}"
fi

set -u

while IFS="|" read -r arch _ package version; do
  apk_file="packages/${arch}/${package}-${version}.apk"
  if [[ -f "$apk_file" ]]; then
    echo "Processing ${apk_file}"
    tmpdir=$(mktemp -d)

    trap 'rm -rf "$tmpdir"' EXIT

    tar -xf "$apk_file" -C "$tmpdir"

    grype -q "$tmpdir" $output_flag
  else
    echo "File ${apk_file} not found."
  fi
done < "packages.log"