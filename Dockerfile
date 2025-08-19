# --- Stage 1: Build ---
# Use the official Golang image as a builder.
FROM golang:1.24.4-alpine AS builder

# Set the working directory inside the container.
WORKDIR /workspace

# Copy Go module files and download dependencies. This leverages Docker layer caching.
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code.
COPY . .

# Build the controller binary.
# CGO_ENABLED=0 creates a static binary.
RUN CGO_ENABLED=0 go build -o /controller ./cmd/controller

# Build the plugin binary.
RUN CGO_ENABLED=0 go build -o /plugin ./cmd/plugin


# --- Stage 2: Final Image ---
# Use a minimal Alpine Linux image as the final base.
FROM alpine:latest

# Copy the controller binary from the builder stage.
COPY --from=builder /controller /controller

# Copy the plugin binary from the builder stage.
COPY --from=builder /plugin /plugin

# Note: We do not set an ENTRYPOINT or CMD here.
# The command will be specified in the Kubernetes Deployment and DaemonSet manifests,
# allowing this single image to run either the controller or the plugin.