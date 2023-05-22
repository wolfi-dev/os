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

BOLD="$(tput -T linux bold)"
RESET="$(tput -T linux sgr0)"

# Make sure Grype is installed.

if ! command -v grype > /dev/null; then
  echo "${BOLD}This script requires Grype to be installed.${RESET} To install Grype, check out https://github.com/anchore/grype#installation."
  exit 1
fi

# Make sure an APK file path was given.

if [[ -z $1 ]]; then
  echo "Usage:

./scripts/grype-scan-apk.sh ${BOLD}path-to-apk-file${RESET} [output-format]

Examples:

./scripts/grype-scan-apk.sh ${BOLD}./ko-0.13.0-r2.apk${RESET}

./scripts/grype-scan-apk.sh ${BOLD}./ko-0.13.0-r2.apk${RESET} json"
  exit 1
fi

# Optionally let the user pass in a Grype output flag argument.

output_flag=""

if [[ ${#2} -gt 0 ]]; then
  output_flag="-o ${2}"
fi

set -u

apk_file="$1"
tmpdir=$(mktemp -d)

trap 'rm -rf "$tmpdir"' EXIT

tar -xf "$apk_file" -C "$tmpdir"

grype -q "$tmpdir" $output_flag
