#!/bin/bash
set -e

if [[ "$INSTALL_MYSQL" ]]; then
  lpm add mysql --global
fi

if [[ "$1" != "history" ]] && [[ "$1" != "init" ]] && type "$1" > /dev/null 2>&1; then
  ## First argument is an actual OS command (except if the command is history or init as it is a liquibase command). Run it
  exec "$@"
else
  if [[ "$*" == *--defaultsFile* ]] || [[ "$*" == *--defaults-file* ]] || [[ "$*" == *--version* ]]; then
    ## Just run as-is
    exec /liquibase/liquibase "$@"
  else
    ## Include standard defaultsFile
    exec /liquibase/liquibase "--defaultsFile=/liquibase/liquibase.docker.properties" "$@"
  fi
fi