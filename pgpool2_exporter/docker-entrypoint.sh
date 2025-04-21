#!/bin/sh
set -ex

setup_data_source_env() {
  export DATA_SOURCE_USER="${POSTGRES_USERNAME}"
  export DATA_SOURCE_PASS="${POSTGRES_PASSWORD}"
  export DATA_SOURCE_URI="${PGPOOL_SERVICE}:${PGPOOL_SERVICE_PORT}/${POSTGRES_DATABASE}?sslmode=${SSLMODE}"
}

main() {
  setup_data_source_env
  exec pgpool2_exporter
}

main "$@"
