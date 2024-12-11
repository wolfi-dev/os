package test

import (
	"context"
	"testing"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	clusterv1 "sigs.k8s.io/cluster-api/api/v1beta1"
	"sigs.k8s.io/controller-runtime/pkg/client/fake"
)

func TestClusterReconciliation(t *testing.T) {
	scheme := runtime.NewScheme()
	if err := clusterv1.AddToScheme(scheme); err != nil {
		t.Fatalf("Failed to add cluster API to scheme: %v", err)
	}

	// Create a fake client
	fakeClient := fake.NewClientBuilder().WithScheme(scheme).Build()

	// Create a test cluster
	cluster := &clusterv1.Cluster{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "test-cluster",
			Namespace: "default",
		},
		Spec: clusterv1.ClusterSpec{
			Paused: false,
		},
	}

	// Create the cluster object
	if err := fakeClient.Create(context.Background(), cluster); err != nil {
		t.Fatalf("Failed to create test cluster: %v", err)
	}

	// Verify cluster was created
	createdCluster := &clusterv1.Cluster{}
	if err := fakeClient.Get(context.Background(),
		types.NamespacedName{
			Namespace: "default",
			Name:      "test-cluster",
		},
		createdCluster); err != nil {
		t.Fatalf("Failed to get created cluster: %v", err)
	}

	// Test cluster spec
	if createdCluster.Spec.Paused {
		t.Error("Expected cluster to not be paused")
	}
}
