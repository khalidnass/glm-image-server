# GLM-Image Server using SGLang
FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3.11 python3.11-venv python3-pip git curl vim \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

WORKDIR /app

# PyTorch
RUN pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cu124

# SGLang base
RUN pip install --no-cache-dir sglang

# Diffusion dependencies + transformers/diffusers from git
RUN pip install --no-cache-dir accelerate sentencepiece protobuf
RUN pip install --no-cache-dir git+https://github.com/huggingface/transformers.git
RUN pip install --no-cache-dir git+https://github.com/huggingface/diffusers.git

RUN mkdir -p /app/models
ENV PYTHONUNBUFFERED=1
ENV HF_HOME=/app/models

EXPOSE 30000

ENV MODEL_PATH=zai-org/GLM-Image
CMD ["sh", "-c", "python -m sglang.launch_server --model-path $MODEL_PATH --port 30000 --host 0.0.0.0"]
