#!/usr/bin/env bash
set -Eeo pipefail

# If the first argument is not 'steampipe', prepend it
if [ "$1" != "steampipe" ]; then
    set -- steampipe "$@"
fi

exec "$@"
