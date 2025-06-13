#!/bin/sh

set -e

case "$1" in
    *.yaml|*.yml) set -- registry serve "$@" ;;
    serve|garbage-collect|help|-*) set -- registry "$@" ;;
esac

exec "$@"
# ref: https://raw.githubusercontent.com/distribution/distribution-library-image/master/entrypoint.sh
