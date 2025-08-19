#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# This script will:
# 1. Create a ResourceClass for the DRA driver.
# 2. Create a PodNetwork custom resource.
# 3. Create a ResourceClaim to request a network from the PodNetwork.
# 4. Create a demo Pod that uses the ResourceClaim.
# 5. Show the logs from the controller and plugin to verify they are working.

echo "---"
echo "INFO: Applying demo resources..."
kubectl apply -f config/demo/

echo "---"
echo "INFO: Waiting for ResourceClaim 'dranet-claim' to be allocated..."
kubectl wait --for=condition=Allocated -n default resourceclaim/dranet-claim --timeout=60s

echo "---"
echo "INFO: Creating the demo pod 'test-pod'..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: demo
    image: nginx
    command: ["/bin/sh", "-c", "sleep 3600"]
  resourceClaims:
  - name: net
    source:
      resourceClaimName: dranet-claim
EOF

echo "---"
echo "INFO: Waiting for 'test-pod' to be running..."
kubectl wait --for=condition=Ready pod/test-pod --timeout=120s
echo "INFO: Pod 'test-pod' is running successfully!"

echo "---"
echo "INFO: Displaying logs from the controller..."
CONTROLLER_POD=$(kubectl get pods -n dranet-system -l control-plane=controller-manager -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n dranet-system "$CONTROLLER_POD" | grep "Reconciling PodNetwork"

echo "---"
echo "INFO: Displaying logs from the node plugin..."
PLUGIN_POD=$(kubectl get pods -n dranet-system -l app=dranet-plugin -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n dranet-system "$PLUGIN_POD" | grep -E "DRA:|NRI:"

echo "---"
echo "✅ DEMO COMPLETE ✅"
echo "To clean up, run: make kind-down"