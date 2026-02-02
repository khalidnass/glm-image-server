# GLM-Image + Wan 2.2 Server using SGLang
# v0.6.0 - Uses official SGLang Docker image as base
#
# Official SGLang image includes:
# - SGLang with diffusion support
# - FlashInfer v0.6.2 (optimized attention)
# - sgl-kernel (custom CUDA kernels)
# - flash-attn (compiled)
# - Triton
# - Python, PyTorch, CUDA
#
# Supported models:
# - GLM-Image (image generation/editing)
# - Wan 2.2 T2V/I2V/TI2V (video generation)
#
# Run (OpenShift/offline):
#   Set MODEL_PATH env var to your mounted model path
#   No internet required - uses local model path

FROM lmsysorg/sglang:latest

# Update transformers/diffusers from git (for GLM-Image/Wan 2.2 support)
RUN pip install --no-cache-dir git+https://github.com/huggingface/transformers.git
RUN pip install --no-cache-dir git+https://github.com/huggingface/diffusers.git

# Wan 2.2 system dependencies (only install if missing)
# - ffmpeg: video encoding/decoding
# - libgl1-mesa-glx: OpenCV dependency (libGL.so.1)
# - libglib2.0-0: OpenCV dependency (GLib)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/* || true

# Wan 2.2 Python dependencies (only install if missing)
# - opencv-python: image/video processing
# - imageio[ffmpeg], imageio-ffmpeg: video export (diffusers export_to_video)
# - easydict: configuration handling
# - ftfy: text processing
RUN pip install --no-cache-dir \
    opencv-python \
    "imageio[ffmpeg]" \
    imageio-ffmpeg \
    easydict \
    ftfy || true

# Verify transformers has GlmImageForConditionalGeneration
RUN python -c "from transformers import GlmImageForConditionalGeneration; print('GLM-Image OK')"

# Verify Wan 2.2 pipeline is available
RUN python -c "from diffusers import WanPipeline; print('WanPipeline OK')"

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
