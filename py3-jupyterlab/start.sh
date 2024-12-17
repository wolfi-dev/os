#!/bin/bash

# TODO: user mgmt
# TODO: command
# TODO: ???

if [ $# -eq 0 ]; then
  echo "Starting shell"
  exec /bin/sh
  exit $?
fi
echo "Starting" "$@"
exec -- "$@"
exit $?

