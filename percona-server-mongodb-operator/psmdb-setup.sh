#!/bin/sh
set -o errexit -o nounset -o errtrace -o pipefail -x

# Mount svc account files for operator
mkdir -p /var/run/secrets/kubernetes.io/serviceaccount
printf "default" > /var/run/secrets/kubernetes.io/serviceaccount/namespace

# Wait for pod to be created
sleep 5

# Grab pod name and set HOSTNAME env
kubectl wait --for=condition=Ready pods -l name=percona-server-mongodb-operator --timeout=60s
export HOSTNAME=$(kubectl get pods --no-headers -l name=percona-server-mongodb-operator | awk '{print $1}')

# Startup psmdb-operator
percona-server-mongodb-operator