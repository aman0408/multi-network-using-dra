# Multi Network using DRA

This project is a proof-of-concept (PoC) demonstrating how to manage multiple network interfaces for Pods in Kubernetes using Dynamic Resource Allocation (DRA) and a Node Resource Interface (NRI) plugin.

It introduces a `PodNetwork` Custom Resource Definition (CRD) to represent a logical network within the cluster. A controller manages the lifecycle of these `PodNetwork` objects, while a DRA/NRI plugin running on each node is responsible for allocating network devices and attaching them to Pods.

## How It Works

1.  **PodNetwork CRD**: A cluster administrator defines a `PodNetwork` resource to represent a logical network.
2.  **ResourceClaim**: A user creates a `ResourceClaim` to request a network interface from a specific `PodNetwork`.
3.  **Pod Consumption**: A Pod is created that references the `ResourceClaim`.
4.  **DRA/NRI Plugin**: The plugin, running on the node where the Pod is scheduled, receives the request from the Kubelet.
5.  **Network Attachment**: The plugin's NRI component moves a network interface from the host into the Pod's network namespace, making it available to the application.

## Prerequisites

To run this PoC, you will need the following tools installed:

-   [Docker](https://docs.docker.com/get-docker/)
-   [Go](https://golang.org/doc/install) (version 1.24 or higher)
-   [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
-   [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## Getting Started

The easiest way to get started is to run the `demo` target in the `Makefile`. This single command will:

1.  Build the controller and plugin binaries.
2.  Create a new KIND cluster.
3.  Build the container images for the controller and plugin and load them into the KIND cluster.
4.  Deploy the `PodNetwork` CRD, controller, and plugin to the cluster.
5.  Create a `dummy0` network interface on the KIND control plane node for testing.
6.  Deploy sample resources, including a `DeviceClass`, `ResourceClaim`, and a sample `Pod`.

To run the demo, execute the following command:

```bash
make demo
```

## Cleanup

To clean up the resources created by the demo, you can use the following `make` targets.

1.  **Undeploy Kubernetes resources**:

    This will delete the sample Pod, `ResourceClaim`, `DeviceClass`, controller, and plugin from the cluster.

    ```bash
    make undeploy
    ```

2.  **Delete the KIND cluster**:

    ```bash
    make kind-down
    ```

3.  **Clean up everything**:

    To delete the KIND cluster and the local binaries, run:

    ```bash
    make clean
    ```

## Development

For development purposes, you can use the individual `make` targets to run each step of the process manually.

-   `make build`: Build the Go binaries.
-   `make docker-build-controller`: Build the controller Docker image.
-   `make docker-build-plugin`: Build the plugin Docker image.
-   `make kind-up`: Create the KIND cluster.
-   `make kind-load`: Load the Docker images into the cluster.
-   `make deploy`: Deploy the Kubernetes manifests.
