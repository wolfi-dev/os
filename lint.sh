#!/usr/bin/env bash

set -euo pipefail

shellquote() {
    command -v python3 >/dev/null ||
        { echo "$*"; return 0; }
    python3 -c 'import sys, shlex; print(shlex.join(sys.argv[1:]))' "$@"
}

stderr() {
    echo "$@" 1>&2
}

yqrun() {
    local rc="" out=""
    yq "$@" && return 0
    rc=$?
    out=$(shellquote "$@")
    stderr "FAIL${fn:+ [$fn]}" "cmd failed $rc:" "$out"
    return $rc
}

ylint() {
  local fn="$1" out=""
  case "$fn" in
      *.yaml) ;;
      *) echo "--- $fn not a yaml file, skipping"
         return 0
  esac

  p=$(yqrun -r '.package.name' "${fn}") || return
  [ -n "$p" ] || { stderr "FAIL [$fn]: empty package name"; return 1; }
  echo "--- package" "$p"

  # Don't specify repositories or keyring for os packages
  if grep -q packages.wolfi.dev/os "${fn}"; then
    yqrun -i 'del(.environment.contents.repositories)' "${fn}" || return
    yqrun -i 'del(.environment.contents.keyring)' "${fn}" || return
  fi

  # Don't specify wolfi-base or any of its packages, or the main package, for test pipelines.
  for pkg in wolfi-base busybox apk-tools wolfi-keys "${p}"; do
    yqrun -i 'del(.test.environment.contents.packages[] | select(. == "'"${pkg}"'"))' "${fn}" ||
        return
  done

  # If .test.environment.contents.packages is empty, remove it all.
  out=$(yqrun -r '.test.environment.contents.packages | length' "${fn}") ||
      return
  if [ "$out" = "0" ]; then
    yqrun -i 'del(.test.environment.contents)' "${fn}" || return
  fi

  yam "${fn}" || {
      stderr "FAIL [$fn]: cmd failed $?: yam $fn"
      return 1
  }
  return 0
}

if [ "${1:-x}" = "_ylint" ]; then
    ylint "$2"
    exit
fi

# If arguments are passed to the command, only lint the files listed.
args=true
if [ "$#" == "0" ]; then
  set -- *.yaml
  args=false
fi

yamls=()
for fn in "$@"; do
  case "$fn" in
      *.yaml) ;;
      *) echo "--- $fn not a yaml file, skipping"
         continue ;;
  esac
  yamls+=( "$fn" )
done

if [ "${#yamls[@]}" = "0" ]; then
    stderr "no yaml files provided"
    exit 1
fi

nprocs=${NPROCS:-""}
if [ -z "$nprocs" ]; then
    nprocs=$(nproc 2>/dev/null) || nprocs=8
fi

printf "%s\0" "${yamls[@]}" |
    xargs -0 --max-args=1 --max-procs="$nprocs" -- "$0" _ylint ||
    exit

if [ "$args" != "true" ]; then
    # New section to check for .sts.yaml files under ./.github/chainguard/
    echo "Checking for .sts.yaml files in ./.github/chainguard/..."
    find .github/chainguard -type f ! -name "*.sts.yaml"
    # shellcheck disable=SC2044
    for file in $(find .github/chainguard -type f); do
      if [[ ! $file =~ \.sts\.yaml$ ]]; then
        echo "ERROR: File $file does not have the required '.sts.yaml' suffix"
        exit 1
      fi
    done
fi
