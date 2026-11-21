#!/bin/sh
# Copy a Lean module tree into an install root, keeping the directory layout.
#
#   install-lean-tree.sh build SRC DEST [PATH ...]
#       copies the importable build artifacts found under SRC (a Lake
#       lib/lean directory): the same kinds the toolchain ships for Init, Lean,
#       and Std. Lake's .trace and .hash files are build-cache metadata and the
#       .c files serve only native compilation, so neither is copied.
#   install-lean-tree.sh src SRC DEST [PATH ...]
#       copies the .lean sources found under SRC (a package checkout).
#
# PATH arguments are relative to SRC and default to the whole tree.
set -eu

kind=$1
src=$2
dest=$3
shift 3
[ "$#" -gt 0 ] || set -- .

# shellcheck disable=SC2016  # the $-expressions are for the inner sh, not this one
copy='dest=$1; shift; for f do install -Dm644 "$f" "$dest/$f"; done'

cd "${src}"
case ${kind} in
  build)
    find "$@" -type f \( -name '*.olean' -o -name '*.olean.private' -o -name '*.olean.server' \
      -o -name '*.ilean' -o -name '*.ir' -o -name '*.ir.sig' \) -exec sh -c "${copy}" _ "${dest}" {} +
    ;;
  src)
    find "$@" -type f -name '*.lean' -exec sh -c "${copy}" _ "${dest}" {} +
    ;;
  *)
    echo "install-lean-tree.sh: unknown kind '${kind}' (expected build or src)" >&2
    exit 2
    ;;
esac
