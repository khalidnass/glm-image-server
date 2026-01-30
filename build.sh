#!/bin/bash
# Build script for GLM-Image Docker image
# Single devel image build for flash-attn compilation and Triton JIT support

set -e

export MAX_JOBS=2

IMAGE_NAME="glm-image-sglang"
BASE_IMAGE="pytorch/pytorch:2.9.1-cuda12.8-cudnn9-devel"
GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD)

echo "=== Pulling base image ==="
docker pull $BASE_IMAGE

echo "=== Building $IMAGE_NAME:$GIT_TAG ==="
docker build --progress=plain -t $IMAGE_NAME:$GIT_TAG .

echo "=== Done ==="
echo "Run with: docker run --gpus all -p 30000:30000 $IMAGE_NAME:$GIT_TAG"
