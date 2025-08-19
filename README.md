# Multi Network using DRA POC

This POC demonstrates the usage of the PodNetwork API using DRA and an NRI plugin.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Go](https://golang.org/doc/install)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## Setup

1. **Create the Kind cluster, build the dranet image and load it into the cluster, and install the CRD and dranet daemonset.**

   ```bash
   make setup
   ```

2. **Add a dummy network interface to the kind worker node.**

   ```bash
   make add-dummy-iface
   ```

3. **Deploy the sample resources.**

   This will create a `DeviceClass`, a `ResourceClaim`, and a sample `Pod` that uses the `ResourceClaim`.

   ```bash
   make run-sample
   ```

## Verification

To verify that the POC is working, check that the `dummy0` interface has been moved into the `pod1` container.

```bash
make verify
```

## Cleanup

1. **Clean up the sample resources.**

   ```bash
   make clean-sample
   ```

2. **Delete the Kind cluster.**

   ```bash
   make clean-cluster
   ```