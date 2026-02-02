#!/bin/bash
# Build script for GLM-Image Docker image
# v0.6.0 - Uses official SGLang Docker image as base

set -e

IMAGE_NAME="glm-image-sglang"
BASE_IMAGE="lmsysorg/sglang:latest"
GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD)

echo "=== Pulling base image ==="
docker pull $BASE_IMAGE

echo "=== Building $IMAGE_NAME:$GIT_TAG ==="
docker build --progress=plain -t $IMAGE_NAME:$GIT_TAG .

echo "=== Done ==="
echo "Run with: docker run --gpus all -p 30000:30000 -e MODEL_PATH=/app/models/GLM-Image -v ./models:/app/models $IMAGE_NAME:$GIT_TAG"
