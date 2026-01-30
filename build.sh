#!/bin/bash
# Build script for GLM-Image Docker image
# Multi-stage build: devel (compile flash-attn) -> runtime (final image)
# Pulls base images first to ensure latest version and faster builds

set -e

export MAX_JOBS=2

IMAGE_NAME="glm-image-sglang"
DEVEL_IMAGE="pytorch/pytorch:2.9.1-cuda12.8-cudnn9-devel"
RUNTIME_IMAGE="pytorch/pytorch:2.9.1-cuda12.8-cudnn9-runtime"
GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD)

echo "=== Pulling base images ==="
docker pull $DEVEL_IMAGE
docker pull $RUNTIME_IMAGE

echo "=== Building $IMAGE_NAME:$GIT_TAG (with flash-attn support) ==="
docker build --progress=plain -t $IMAGE_NAME:$GIT_TAG .

echo "=== Done ==="
echo "Run with: docker run --gpus all -p 30000:30000 $IMAGE_NAME:$GIT_TAG"
