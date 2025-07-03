#!/bin/bash
set -euxo pipefail

COMPONENTS="$1"  # Component name: access-management | admission-webhook
KUBEFLOW_TAG="$2"  # Kubeflow version tag like v$KUBEFLOW_TAG

kubectl create ns test-ns || true

case "$COMPONENTS" in

access-management)
    echo "Running Access Management API test..."
    kubectl apply -f https://raw.githubusercontent.com/kubeflow/manifests/v$KUBEFLOW_TAG/apps/profiles/upstream/crd/bases/kubeflow.org_profiles.yaml

    echo "Simulating namespace-labels.yaml..."
    mkdir -p /etc/profile-controller
    cat <<EOF >/etc/profile-controller/namespace-labels.yaml
kubeflow.org/creator: kubeflow
environment: test
EOF

  /usr/bin/access-management &
  pid=$!
  sleep 10

  echo "Testing profile creation"
  curl -s -w '%{http_code}\n' -o /dev/null -X POST -H "Content-Type: application/json" \
    -d '{"metadata":{"name":"user1"},"spec":{"owner":{"kind":"User","name":"test@kubeflow.org"}}}' \
    http://127.0.0.1:8081/kfam/v1/profiles


  echo "Confirming profile exists"
  kubectl get profile

  kill $pid
    ;;

admission-webhook)
  # Namespace and CRD
  kubectl create ns kubeflow || true
  mkdir -p /tmp/webhook-certs
  openssl req -x509 -newkey rsa:4096 -days 365 -nodes -keyout /tmp/webhook-certs/key.pem -out /tmp/webhook-certs/cert.pem -subj "/CN=localhost"


  kubectl apply -f https://raw.githubusercontent.com/kubeflow/manifests/v$KUBEFLOW_TAG/apps/admission-webhook/upstream/base/crd.yaml

  # Launch webhook
  /usr/bin/webhook -tlsCertFile /tmp/webhook-certs/cert.pem -tlsKeyFile /tmp/webhook-certs/key.pem &

  pid=$!

  sleep 5

  echo "Fetching manifests..."
  mkdir -p /tmp/admission-webhook
  cd /tmp/admission-webhook

  kubectl apply -f https://raw.githubusercontent.com/kubeflow/manifests/v$KUBEFLOW_TAG/apps/admission-webhook/upstream/base/crd.yaml

  echo "Creating namespace..."
  kubectl create ns kubeflow || true

  echo "Deploying Service..."
  kubectl apply -f - <<EOF
  apiVersion: v1
  kind: Service
  metadata:
    name: poddefault-webhook
    namespace: kubeflow
  spec:
    ports:
    - port: 443
      targetPort: 8443
      protocol: TCP
    selector:
      app: poddefault-webhook
EOF

  echo "Applying MutatingWebhookConfiguration..."
  kubectl apply -f - <<EOF
  apiVersion: admissionregistration.k8s.io/v1
  kind: MutatingWebhookConfiguration
  metadata:
    name: mutating-webhook-configuration
  webhooks:
  - admissionReviewVersions:
    - v1beta1
    - v1
    clientConfig:
      caBundle: ""
      service:
        name: poddefault-webhook
        namespace: kubeflow
        path: /apply-poddefault
    sideEffects: None
    failurePolicy: Fail
    name: poddefault-webhook.kubeflow.org
    namespaceSelector:
      matchLabels:
        app.kubernetes.io/part-of: kubeflow-profile
    rules:
    - apiGroups:
      - ""
      apiVersions:
      - v1
      operations:
      - CREATE
      resources:
      - pods
EOF

  echo "Testing PodDefault CR..."
  kubectl apply -f - <<EOF
apiVersion: kubeflow.org/v1alpha1
kind: PodDefault
metadata:
  name: add-gcp-secret
  namespace: kubeflow
spec:
  selector:
    matchLabels:
      add-gcp-secret: "true"
  desc: "Add GCP credential"
  volumeMounts:
  - name: secret-volume
    mountPath: /secret/gcp
  volumes:
  - name: secret-volume
    secret:
      secretName: gcp-secret
EOF

  echo "Listing PodDefaults..."
  kubectl get poddefaults -n kubeflow

  kill $pid
    ;;

*)
    echo "No functional test defined for $COMPONENTS"
    exit 0
    ;;
esac
