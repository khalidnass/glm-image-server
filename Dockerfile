# GLM-Image Server using SGLang
# Following OFFICIAL installation from https://huggingface.co/zai-org/GLM-Image
#
# Base image includes: Python 3.11, PyTorch 2.9.1, CUDA 12.8, cuDNN 9
# Target: H20 (production), A100 (testing)
#
# Run (OpenShift/offline):
#   Set MODEL_PATH env var to your mounted model path
#   No internet required - uses local model path

FROM pytorch/pytorch:2.9.1-cuda12.8-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl vim \
    && rm -rf /var/lib/apt/lists/*

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

CMD ["sh", "-c", "sglang serve --model-path $MODEL_PATH --port 30000 --host 0.0.0.0"]
