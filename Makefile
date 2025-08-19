.PHONY: all build docker-build kind-up kind-load deploy demo clean undeploy kind-down
IMG ?= dranet-plugin:latest
KIND_CLUSTER_NAME=mn-dra-poc

# Build the Go binaries for the controller and plugin
build:
	@echo ">> Building Go binaries..."
	go build -o bin/controller ./cmd/controller
	go build -o bin/plugin ./cmd/plugin

# Build the Docker image containing both binaries
docker-build:
	@echo ">> Building Docker image..."
	docker build -t ${IMG} .

# Create a kind cluster using the specific config
kind-up:
	@echo ">> Creating Kind cluster '${KIND_CLUSTER_NAME}'..."
	kind create cluster --name ${KIND_CLUSTER_NAME} --config=./hack/kind-config.yaml

# Load the Docker image into the kind cluster
kind-load: docker-build
	@echo ">> Loading Docker image '${IMG}' into Kind..."
	kind load docker-image ${IMG} --name ${KIND_CLUSTER_NAME}

# Deploy all Kubernetes manifests to the cluster
deploy:
	@echo ">> Deploying Kubernetes manifests..."
	kubectl apply -f config/crd
	kubectl apply -f config/controller
	kubectl apply -f config/plugin

# Run the full demo from start to finish
demo: build kind-up docker-build kind-load deploy
	@echo ">> Running demo script..."
# 	./hack/demo.sh

# Remove all deployed Kubernetes manifests
undeploy:
	@echo ">> Deleting Kubernetes manifests..."
	kubectl delete -f config/plugin --ignore-not-found
	kubectl delete -f config/controller --ignore-not-found
	kubectl delete -f config/crd --ignore-not-found

# Delete the kind cluster
kind-down:
	@echo ">> Deleting Kind cluster '${KIND_CLUSTER_NAME}'..."
	kind delete cluster --name ${KIND_CLUSTER_NAME}

# Clean up local binaries
clean: kind-down
	@echo ">> Cleaning up local binaries..."
	rm -rf ./bin