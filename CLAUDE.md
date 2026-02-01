# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GLM-Image Server using SGLang - a Docker container that serves the [GLM-Image](https://huggingface.co/zai-org/GLM-Image) diffusion model with OpenAI-compatible API endpoints. Designed for offline/OpenShift deployment.

## Commands

### Build and run
```bash
./build.sh                    # Build image tagged with git tag (e.g., glm-image-sglang:v0.4.4)
docker run --gpus all -p 30000:30000 -e MODEL_PATH=/app/models/GLM-Image -v ./models:/app/models glm-image-sglang:v0.4.4
```

### Save/load Docker image (offline deployment)
```bash
docker save glm-image-sglang:v0.4.4 -o glm-image-sglang-v0.4.4.tar
docker load -i glm-image-sglang-v0.4.4.tar
```

### Test the API
```bash
curl http://localhost:30000/health
curl http://localhost:30000/v1/models
```

See README.md for complete API usage examples and parameters.

## Architecture

Single devel image Docker build:

- **Dockerfile** - Single-stage build using devel image:
  - Uses devel image with full CUDA toolkit (gcc, nvcc, ninja)
  - Compiles flash-attn from source
  - All build tools available at runtime for Triton JIT compilation
  - Installs SGLang + transformers + diffusers from git main
  - Sets `HF_HUB_OFFLINE=1` for air-gapped environments
  - Runs as non-root user (UID 1001) for OpenShift compatibility
  - Image size ~11GB (vs ~6GB for multi-stage, negligible vs ~20GB model)
- **build.sh** - Pulls devel base image, builds with `--progress=plain` to show output. Tags image with current git tag or short commit hash. Uses `MAX_JOBS=2` to limit parallel compilation.
- **download-packages.sh** - Downloads pip packages to `pip-cache/` (for reference/offline scenarios, but Dockerfile uses git URLs directly)
- **SGLang server** - Port 30000, OpenAI-compatible API (`/v1/images/generations`, `/v1/images/edits`)

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL_PATH` | (required) | Local path to GLM-Image model |
| `HF_HOME` | /app/models | Model cache directory |
| `HF_TOKEN` | - | HuggingFace token if needed |

## Known Issues

### Version pinning does not work
- **Do NOT pin SGLang** - v0.5.8 fails to run; must use git main branch
- **Do NOT pin diffusers** - GLM-Image support requires git main
- **Do NOT pin transformers** - GLM-Image support requires git main
- Tag `sglang-v0.5.8` exists for reference but Dockerfile correctly uses main branch

### Docker tagging
- **Do NOT use `latest` tag** - always use git tag version (e.g., `glm-image-sglang:v0.4.4`)

### Pod restarts during model loading (OpenShift/Kubernetes)
- Model loading takes ~2 minutes
- Default health probes kill pod before ready
- Fix: Add startupProbe with failureThreshold: 30, periodSeconds: 10

### Pod OOMKilled during model loading
- Model loading requires ~40-50GB RAM (not GPU VRAM)
- Pod crashes immediately with no visible error in logs
- Fix: Set memory limit to 64Gi in deployment

### flash-attn (Hopper GPUs - H20/H100)
- **flash-attn 2.x is now included** - compiled from source in devel image
- Warning about `flash_attn 3 package` may still appear - this is a separate Hopper-specific optimization
- Server works with flash-attn 2.x, flash-attn 3 would provide additional performance on H100/H20

### Missing C compiler for Triton JIT
- Error: `Failed to find C compiler`
- Fix: Using devel image provides gcc, nvcc, and all build tools (already done)

### Missing libnuma.so.1
- Error: `ImportError: libnuma.so.1: cannot open shared object file`
- Fix: Add `libnuma1` to apt-get install in Dockerfile (already done)
