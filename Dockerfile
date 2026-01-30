# GLM-Image Server using SGLang
# Following OFFICIAL installation from https://huggingface.co/zai-org/GLM-Image
#
# Single devel image build:
# - Devel image provides gcc, nvcc, ninja for flash-attn compilation and Triton JIT
# - All build tools available at runtime
#
# Base image includes: Python 3.11, PyTorch 2.9.1, CUDA 12.8, cuDNN 9
# Target: H20 (production), A100 (testing)
#
# Run (OpenShift/offline):
#   Set MODEL_PATH env var to your mounted model path
#   No internet required - uses local model path

FROM pytorch/pytorch:2.9.1-cuda12.8-cudnn9-devel

ENV DEBIAN_FRONTEND=noninteractive

# System dependencies
# - git, curl, vim: basic tools
# - libnuma1: required by sgl_kernel for GPU operations
# - ninja-build: for flash-attn compilation
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl vim \
    libnuma1 \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# Install flash-attn (compiles from source)
# Limit parallel jobs to prevent system freeze (default uses all cores)
ENV MAX_JOBS=2
# Only compile for target GPU architectures (reduces compile time and memory)
# 9.0 = H100/H20 (Hopper)
ENV TORCH_CUDA_ARCH_LIST="9.0"
RUN pip install --no-cache-dir packaging ninja wheel setuptools
RUN pip install -v flash-attn --no-build-isolation

# Official GLM-Image installation (from https://huggingface.co/zai-org/GLM-Image):
# pip install "sglang[diffusion] @ git+https://github.com/sgl-project/sglang.git#subdirectory=python"
# pip install git+https://github.com/huggingface/transformers.git
# pip install git+https://github.com/huggingface/diffusers.git

RUN pip install --no-cache-dir \
    "sglang[diffusion] @ git+https://github.com/sgl-project/sglang.git#subdirectory=python"

RUN pip install --no-cache-dir \
    git+https://github.com/huggingface/transformers.git

RUN pip install --no-cache-dir \
    git+https://github.com/huggingface/diffusers.git

# Verify flash-attn is available
RUN python -c "import flash_attn; print(f'flash-attn {flash_attn.__version__} OK')"

# Verify transformers has GlmImageForConditionalGeneration
RUN python -c "from transformers import GlmImageForConditionalGeneration; print('GlmImageForConditionalGeneration OK')"

WORKDIR /app
RUN mkdir -p /app/models

ENV PYTHONUNBUFFERED=1
ENV HF_HOME=/app/models
ENV HF_HUB_OFFLINE=1

# MODEL_PATH must be set by user at runtime
ENV MODEL_PATH=

EXPOSE 30000

# OpenShift compatibility: run as arbitrary UID with group 0
RUN chgrp -R 0 /app && chmod -R g=u /app
RUN mkdir -p /tmp /.cache /.triton /.config && chmod 775 /tmp /.cache /.triton /.config
USER 1001

CMD ["sh", "-c", "sglang serve --model-path $MODEL_PATH --port 30000 --host 0.0.0.0"]
