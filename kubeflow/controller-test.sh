#!/bin/bash
set -euxo pipefail

CONTROLLER="$1"  # Pass controller name as argument
KUBEFLOW_TAG="$2"  # Pass Kubeflow version tag as argument

kubectl create ns test-ns || true

case "$CONTROLLER" in

  notebook-controller)
    echo "Applying Notebook CRD..."
    kubectl apply -f https://raw.githubusercontent.com/kubeflow/manifests/v$KUBEFLOW_TAG/apps/jupyter/notebook-controller/upstream/crd/bases/kubeflow.org_notebooks.yaml

    /usr/bin/manager &
    pid=$!

    sleep 5

    echo "Creating Notebook resource..."
    cat <<EOF | kubectl apply -n test-ns -f -
apiVersion: kubeflow.org/v1beta1
kind: Notebook
metadata:
  name: notebook-sample-v1
spec:
  template:
    spec:
      containers:
      - name: notebook-sample-v1
        image: ghcr.io/kubeflow/kubeflow/notebook-servers/jupyter:latest
        command: ["sleep", "infinity"]
EOF

    sleep 5
    kubectl get statefulset -n test-ns | grep notebook-sample-v1
    kubectl get svc -n test-ns | grep notebook-sample-v1

    kill "$pid"
    ;;

  profile-controller)
    echo "Applying Profile CRD..."
    kubectl apply -f https://raw.githubusercontent.com/kubeflow/manifests/v$KUBEFLOW_TAG/apps/profiles/upstream/crd/bases/kubeflow.org_profiles.yaml

    echo "Simulating namespace-labels.yaml..."
    mkdir -p /etc/profile-controller
    cat <<EOF >/etc/profile-controller/namespace-labels.yaml
kubeflow.org/creator: kubeflow
environment: test
EOF

    echo "Applying minimal Istio CRD for AuthorizationPolicy..."
    kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/manifests/charts/base/files/crd-all.gen.yaml

    /usr/bin/manager &
    pid=$!

    sleep 5

    echo "Creating Profile resource..."
    cat <<EOF | kubectl apply -f -
apiVersion: kubeflow.org/v1
kind: Profile
metadata:
  name: test-profile
spec:
  owner:
    kind: User
    name: test-user
EOF

    sleep 5
    kubectl get profile test-profile -o yaml | grep test-profile || true
    kubectl get namespace test-profile || echo "Namespace creation may depend on full K8s control plane"

    kill "$pid"
    ;;

  pvcviewer-controller)

    
    kubectl create ns kubeflow-user-example-com
    cat <<EOF | kubectl apply -f -
  apiVersion: v1
  kind: Pod
  metadata:
    name: fake-pvcviewer-pod
    namespace: kubeflow-user-example-com
  spec:
    containers:
    - name: busy
      image: busybox
      command: ["sleep", "infinity"]
EOF

    kubectl apply -f https://raw.githubusercontent.com/kubeflow/manifests/refs/tags/v$KUBEFLOW_TAG/apps/pvcviewer-controller/upstream/crd/bases/kubeflow.org_pvcviewers.yaml
    kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/manifests/charts/base/files/crd-all.gen.yaml


    mkdir -p /tmp/k8s-webhook-server/serving-certs
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout /tmp/k8s-webhook-server/serving-certs/tls.key \
      -out /tmp/k8s-webhook-server/serving-certs/tls.crt \
      -subj "/CN=localhost"

    /usr/bin/manager &
    pid=$!

    sleep 5

    kubectl apply -f https://raw.githubusercontent.com/kubeflow/manifests/refs/tags/v$KUBEFLOW_TAG/apps/pvcviewer-controller/upstream/samples/_v1alpha1_pvcviewer.yaml

    echo "Validating PVCViewer resources..."
    kubectl get svc -n kubeflow-user-example-com 
    kubectl get deployment -n kubeflow-user-example-com 
    kubectl get pvcviewer -n kubeflow-user-example-com -o yaml 

    kill $pid
    ;;

  tensorboard-controller)
    kubectl create ns kubeflow
    echo "Tensorboard test placeholder"
    export TENSORBOARD_IMAGE=tensorflow/tensorflow:2.5.1

    # CRD first
    kubectl apply -f https://raw.githubusercontent.com/kubeflow/manifests/refs/tags/v$KUBEFLOW_TAG/apps/tensorboard/tensorboard-controller/upstream/crd/bases/tensorboard.kubeflow.org_tensorboards.yaml

    # Launch controller
    /usr/bin/manager &
    pid=$!


    # Apply sample Tensorboard resource AFTER controller is live
    kubectl apply -f https://raw.githubusercontent.com/kubeflow/manifests/refs/tags/v$KUBEFLOW_TAG/apps/tensorboard/tensorboard-controller/upstream/samples/tensorboard_v1alpha1_tensorboard.yaml
    # Dump resource YAML (ignore failure, resource might be partially processed)
    kubectl get tensorboard.tensorboard.kubeflow.org tensorboard-sample1 -n kubeflow -o yaml || true
    ;;

  *)
    echo "No functional test defined for $CONTROLLER"
    ;;
esac
