#!/usr/bin/env bash

for clusters in $(
  gcloud container clusters list --project="${1}" \
    --format="csv[no-heading](name,createTime,zone)")
do
  IFS=',' read -r -a infoArray<<< "${clusters}"
  NAME="${infoArray[0]}"
  CREATE_TIME="${infoArray[1]}"
  ZONE="${infoArray[2]}"
  FORMATED_CREATE_TIME=$(date -u -d "${CREATE_TIME}" +"%Y-%m-%d")
  echo "  NAME: ${NAME}"
  echo "  CREATE_TIME: ${CREATE_TIME} / ${FORMATED_CREATE_TIME}"

  CUTOFF_DATE=$(date -I -d "7 hours ago")
  if [[ ${FORMATED_CREATE_TIME} < ${CUTOFF_DATE} ]]; then
    echo "Cluster ${NAME}(${FORMATED_CREATE_TIME}) is older than ${CUTOFF_DATE} will terminate"
    gcloud container clusters delete "${NAME}" \
    --zone "${ZONE}" \
    --quiet
  fi
done
