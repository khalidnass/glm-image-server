# GLM-Image + Wan 2.2 Server (SGLang)

Docker-based server for image and video generation using SGLang with **OpenAI-compatible API**.

## Supported Models (v0.6.0)

| Model | Type | HuggingFace |
|-------|------|-------------|
| GLM-Image | Image generation/editing | [zai-org/GLM-Image](https://huggingface.co/zai-org/GLM-Image) |
| Wan 2.2 T2V | Text-to-video | [Wan-AI/Wan2.2-T2V-A14B-Diffusers](https://huggingface.co/Wan-AI/Wan2.2-T2V-A14B-Diffusers) |
| Wan 2.2 I2V | Image-to-video | [Wan-AI/Wan2.2-I2V-A14B-Diffusers](https://huggingface.co/Wan-AI/Wan2.2-I2V-A14B-Diffusers) |
| Wan 2.2 TI2V | Text+image-to-video | [Wan-AI/Wan2.2-TI2V-5B-Diffusers](https://huggingface.co/Wan-AI/Wan2.2-TI2V-5B-Diffusers) |

Tested on **NVIDIA H20 GPUs**. OpenShift compatible - runs as non-root user with arbitrary UID support.

## Requirements

- Docker with NVIDIA GPU support (nvidia-docker2)
- NVIDIA GPU with 24GB+ VRAM (H20, H100, A100, or similar)
- CUDA 12.4+ compatible driver
- 64GB+ system RAM for model loading

## Image Comparison: Official SGLang vs v0.6.0

The v0.6.0 image is based on the official SGLang image with modifications for GLM-Image and Wan 2.2 support:

| Category | Official SGLang (`lmsysorg/sglang:latest`) | v0.6.0 Custom (`glm-image-sglang:v0.6.0`) |
|----------|-------------------------------------------|-------------------------------------------|
| **Base** | NVIDIA CUDA 12.9.1 | Same (inherits from official) |
| **transformers** | 4.57.1 (PyPI) | 5.0.1.dev0 (git main) |
| **diffusers** | Not installed | 0.37.0.dev0 (git main) |
| **huggingface_hub** | 0.36.0 | 1.3.7 |
| **opencv-python** | Not installed | 4.13.0.90 |
| **imageio-ffmpeg** | Not installed | 0.6.0 |
| **easydict** | Not installed | 1.13 |
| **ftfy** | Not installed | 6.3.1 |
| **HF_HUB_OFFLINE** | Not set | `1` (air-gapped support) |
| **HF_HOME** | Not set | `/app/models` |
| **User** | root (UID 0) | 1001 (non-root for OpenShift) |
| **WORKDIR** | `/sgl-workspace/sglang` | `/app` |

### Why These Changes?

- **transformers/diffusers from git main**: GLM-Image and Wan 2.2 models require unreleased features not yet in PyPI versions
- **opencv/imageio-ffmpeg**: Required by Wan 2.2 for video encoding
- **HF_HUB_OFFLINE=1**: Enables air-gapped deployment without internet access
- **Non-root user**: Required for OpenShift compatibility (arbitrary UID support)

## Quick Start

### 1. Build the Docker image

```bash
./build.sh
# Creates: glm-image-sglang:<git-tag>
```

### 2. Run the server

**GLM-Image (image generation):**
```bash
docker run --gpus all -p 30000:30000 \
  -e MODEL_PATH=/app/models/GLM-Image \
  -v ./models:/app/models \
  glm-image-sglang:v0.6.0
```

**Wan 2.2 T2V (text-to-video):**
```bash
docker run --gpus all -p 30000:30000 \
  -e MODEL_PATH=/app/models/Wan2.2-T2V-A14B-Diffusers \
  -v ./models:/app/models \
  glm-image-sglang:v0.6.0
```

**Wan 2.2 I2V (image-to-video):**
```bash
docker run --gpus all -p 30000:30000 \
  -e MODEL_PATH=/app/models/Wan2.2-I2V-A14B-Diffusers \
  -v ./models:/app/models \
  glm-image-sglang:v0.6.0
```

### 3. Access the API

- API: http://localhost:30000
- Image endpoints: `/v1/images/generations`, `/v1/images/edits`
- Video endpoints: `/v1/video/generations`
- Info: `/v1/models`, `/health`

## Load from tar (offline deployment)

```bash
docker load -i glm-image-sglang-v0.6.0.tar
docker run --gpus all -p 30000:30000 \
  -e MODEL_PATH=/app/models/GLM-Image \
  -v ./models:/app/models \
  glm-image-sglang:v0.6.0
```

## API Endpoints

### Image (GLM-Image)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/v1/images/generations` | POST | Text-to-image generation |
| `/v1/images/edits` | POST | Image-to-image editing |

### Video (Wan 2.2)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/v1/video/generations` | POST | Text-to-video or image-to-video generation |

### Info

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/v1/models` | GET | List available models |
| `/health` | GET | Health check |

## API Parameters

### Text-to-Image (`/v1/images/generations`)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `prompt` | string | required | Text description. Enclose text to render in quotes. |
| `model` | string | zai-org/GLM-Image | Model identifier |
| `size` | string | 1024x1024 | Image dimensions (must be divisible by 32) |
| `n` | int | 1 | Number of images to generate (1-4) |
| `response_format` | string | b64_json | `b64_json` or `url` |
| `num_inference_steps` | int | 50 | Diffusion steps (higher = better quality, slower) |
| `guidance_scale` | float | 1.5 | Prompt adherence strength |
| `seed` | int | random | For reproducible results |

### Image-to-Image (`/v1/images/edits`)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `image` | file | required | Input image file |
| `prompt` | string | required | Edit description |
| `model` | string | zai-org/GLM-Image | Model identifier |
| `size` | string | 1024x1024 | Output dimensions (must be divisible by 32) |
| `n` | int | 1 | Number of images to generate (1-4) |
| `response_format` | string | b64_json | `b64_json` or `url` |
| `num_inference_steps` | int | 50 | Diffusion steps |
| `guidance_scale` | float | 1.5 | Prompt adherence strength |
| `seed` | int | random | For reproducible results |

### Video Generation (`/v1/video/generations`) - Wan 2.2

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `prompt` | string | required | Text description for video |
| `model` | string | auto | Model identifier (uses MODEL_PATH) |
| `image` | file | optional | Input image for I2V/TI2V models |
| `size` | string | 832x480 | Video dimensions (width x height) |
| `num_frames` | int | 81 | Number of frames (affects video length) |
| `fps` | int | 16 | Frames per second |
| `num_inference_steps` | int | 50 | Diffusion steps |
| `guidance_scale` | float | 5.0 | Prompt adherence strength |
| `seed` | int | random | For reproducible results |
| `response_format` | string | b64_json | `b64_json` or `url` |

## Examples

### Text-to-Image

```bash
curl http://localhost:30000/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A beautiful sunset over mountains",
    "size": "1024x1024",
    "response_format": "b64_json"
  }' | python3 -c "import sys, json, base64; open('output.png', 'wb').write(base64.b64decode(json.load(sys.stdin)['data'][0]['b64_json']))"
```

### Image-to-Image (Edit)

```bash
curl -s -X POST "http://localhost:30000/v1/images/edits" \
  -F "model=zai-org/GLM-Image" \
  -F "image=@cond.jpg" \
  -F "prompt=Replace the background of the snow forest with an underground station featuring an automatic escalator." \
  -F "response_format=b64_json" \
  | python3 -c "import sys, json, base64; open('output_i2i.png', 'wb').write(base64.b64decode(json.load(sys.stdin)['data'][0]['b64_json']))"
```

> **Note**: Image editing may have issues in some SGLang versions. If you get a `RuntimeError: Model generation returned no output`, try updating SGLang or use text-to-image generation instead.

### Text-to-Video (Wan 2.2 T2V)

```bash
curl http://localhost:30000/v1/video/generations \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A cat walking through a garden",
    "size": "832x480",
    "num_frames": 81,
    "num_inference_steps": 50,
    "response_format": "b64_json"
  }' | python3 -c "import sys, json, base64; open('output.mp4', 'wb').write(base64.b64decode(json.load(sys.stdin)['data'][0]['b64_json']))"
```

### Image-to-Video (Wan 2.2 I2V)

```bash
curl -s -X POST "http://localhost:30000/v1/video/generations" \
  -F "image=@input.jpg" \
  -F "prompt=The scene comes alive with gentle motion" \
  -F "size=832x480" \
  -F "num_frames=81" \
  -F "response_format=b64_json" \
  | python3 -c "import sys, json, base64; open('output.mp4', 'wb').write(base64.b64decode(json.load(sys.stdin)['data'][0]['b64_json']))"
```

### Python Examples

```bash
pip install requests openai
```

#### Text-to-Image, then Edit

```python
import requests
import base64

BASE_URL = "http://localhost:30000"

# Step 1: Generate an image
response = requests.post(
    f"{BASE_URL}/v1/images/generations",
    json={
        "prompt": "A cat sitting on a mountain",
        "size": "1024x1024",
        "response_format": "b64_json"
    },
    timeout=600
)

data = response.json()
img_bytes = base64.b64decode(data["data"][0]["b64_json"])

with open("generated.png", "wb") as f:
    f.write(img_bytes)

print("Generated image saved to generated.png")

# Step 2: Edit the generated image
with open("generated.png", "rb") as f:
    files = {"image": ("generated.png", f, "image/png")}
    data = {
        "model": "zai-org/GLM-Image",
        "prompt": "Add a rainbow in the sky",
        "response_format": "b64_json"
    }
    response = requests.post(f"{BASE_URL}/v1/images/edits", files=files, data=data, timeout=600)

result = response.json()
img_bytes = base64.b64decode(result["data"][0]["b64_json"])

with open("edited.png", "wb") as f:
    f.write(img_bytes)

print("Edited image saved to edited.png")


#### Image Edit (standalone)

```python
import requests
import base64

BASE_URL = "http://localhost:30000"

with open("cond.jpg", "rb") as f:
    files = {"image": ("cond.jpg", f, "image/jpeg")}
    data = {
        "model": "zai-org/GLM-Image",
        "prompt": "Replace the background of the snow forest with an underground station featuring an automatic escalator.",
        "response_format": "b64_json"
    }
    response = requests.post(f"{BASE_URL}/v1/images/edits", files=files, data=data, timeout=600)

if response.status_code == 200:
    result = response.json()
    img_bytes = base64.b64decode(result["data"][0]["b64_json"])
    with open("output_i2i.png", "wb") as f:
        f.write(img_bytes)
    print("Edited image saved to output_i2i.png")
else:
    print(f"Error: {response.text}")
```

#### High Quality vs Fast Generation

```python
import requests
import base64

BASE_URL = "http://localhost:30000"

# HIGH QUALITY - slower, better results
response = requests.post(
    f"{BASE_URL}/v1/images/generations",
    json={
        "prompt": "A detailed portrait of a medieval knight",
        "size": "1536x1536",           # Higher resolution
        "num_inference_steps": 100,     # More steps = better quality
        "guidance_scale": 2.0,          # Stronger prompt adherence
        "response_format": "b64_json"
    },
    timeout=600
)

data = response.json()
with open("high_quality.png", "wb") as f:
    f.write(base64.b64decode(data["data"][0]["b64_json"]))

print("High quality image saved")

# FAST / LOW QUALITY - quicker preview
response = requests.post(
    f"{BASE_URL}/v1/images/generations",
    json={
        "prompt": "A detailed portrait of a medieval knight",
        "size": "512x512",              # Lower resolution
        "num_inference_steps": 20,      # Fewer steps = faster
        "guidance_scale": 1.0,          # Less strict
        "response_format": "b64_json"
    },
    timeout=120
)

data = response.json()
with open("fast_preview.png", "wb") as f:
    f.write(base64.b64decode(data["data"][0]["b64_json"]))

print("Fast preview saved")
```

| Setting | Fast/Preview | Standard | High Quality |
|---------|--------------|----------|--------------|
| `size` | 512x512 | 1024x1024 | 1536x1536 |
| `num_inference_steps` | 20 | 50 | 100 |
| `guidance_scale` | 1.0 | 1.5 | 2.0 |

#### Text-to-Video (Wan 2.2)

```python
import requests
import base64

BASE_URL = "http://localhost:30000"

response = requests.post(
    f"{BASE_URL}/v1/video/generations",
    json={
        "prompt": "A cat walking through a beautiful garden with flowers",
        "size": "832x480",
        "num_frames": 81,
        "num_inference_steps": 50,
        "guidance_scale": 5.0,
        "response_format": "b64_json"
    },
    timeout=1200  # Video generation takes longer
)

data = response.json()
video_bytes = base64.b64decode(data["data"][0]["b64_json"])

with open("output.mp4", "wb") as f:
    f.write(video_bytes)

print("Video saved to output.mp4")
```

#### Image-to-Video (Wan 2.2 I2V)

```python
import requests
import base64

BASE_URL = "http://localhost:30000"

with open("input.jpg", "rb") as f:
    files = {"image": ("input.jpg", f, "image/jpeg")}
    data = {
        "prompt": "The scene comes alive with gentle motion",
        "size": "832x480",
        "num_frames": 81,
        "response_format": "b64_json"
    }
    response = requests.post(
        f"{BASE_URL}/v1/video/generations",
        files=files,
        data=data,
        timeout=1200
    )

if response.status_code == 200:
    result = response.json()
    video_bytes = base64.b64decode(result["data"][0]["b64_json"])
    with open("output.mp4", "wb") as f:
        f.write(video_bytes)
    print("Video saved to output.mp4")
else:
    print(f"Error: {response.text}")
```

#### Health Check and List Models

```python
import requests

BASE_URL = "http://localhost:30000"

# Health check
health = requests.get(f"{BASE_URL}/health")
print(f"Health: {health.json()}")

# List models
models = requests.get(f"{BASE_URL}/v1/models")
print(f"Models: {models.json()}")
```

#### Using OpenAI SDK

```python
from openai import OpenAI
import base64

client = OpenAI(
    base_url="http://localhost:30000/v1",
    api_key="not-needed"
)

# Step 1: Generate an image
response = client.images.generate(
    model="zai-org/GLM-Image",
    prompt='A robot painting with the text "Art by AI" on canvas',
    size="1024x1024",
    response_format="b64_json"
)

with open("generated.png", "wb") as f:
    f.write(base64.b64decode(response.data[0].b64_json))

print("Generated image saved to generated.png")

# Step 2: Edit the generated image
with open("generated.png", "rb") as img_file:
    response = client.images.edit(
        model="zai-org/GLM-Image",
        image=img_file,
        prompt="Make it look like a watercolor painting",
        size="1024x1024",
        response_format="b64_json"
    )

with open("edited.png", "wb") as f:
    f.write(base64.b64decode(response.data[0].b64_json))

print("Edited image saved to edited.png")
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL_PATH` | (required) | Local path to model (GLM-Image or Wan 2.2) |
| `HF_HOME` | /app/models | Model cache directory |
| `HF_TOKEN` | - | HuggingFace token (if needed) |

## Tips

### Image Generation (GLM-Image)

- **Text rendering**: Enclose text in quotation marks in your prompt (e.g., `"Hello World"`)
- **Dimensions**: Must be divisible by 32 (e.g., 1024x1024, 1152x896, 896x1152)
- **Quality**: Increase `num_inference_steps` (50-100) for better results
- **Reproducibility**: Use same `seed` value to get identical outputs

### Video Generation (Wan 2.2)

- **Dimensions**: Common sizes are 832x480 (landscape) or 480x832 (portrait)
- **Frame count**: 81 frames at 16fps = ~5 second video
- **Model selection**: Use T2V for text-only, I2V for animating a still image, TI2V for text+image
- **Memory**: Video generation requires significant GPU VRAM (~40GB+ for A14B models)
- **Quality**: Increase `num_inference_steps` (50-100) for smoother motion

## Known Issues

### Pod restarts during model loading (OpenShift/Kubernetes)
Model loading takes ~2 minutes. Default health probes will kill the pod before it's ready.

**Fix**: Configure startup probe in your deployment:
```yaml
startupProbe:
  httpGet:
    path: /health
    port: 30000
  failureThreshold: 30
  periodSeconds: 10
  # Allows 5 minutes for startup
```

### flash_attn3 not installed (Hopper GPUs)
On H20/H100 GPUs, you may see:
```
flash_attn 3 package is not installed. It's recommended to install flash_attn3 on hopper, otherwise performance is sub-optimal
```
**Fix**: Use `devel` base image (has nvcc) and add to Dockerfile:
```dockerfile
FROM pytorch/pytorch:2.9.1-cuda12.8-cudnn9-devel
# ... other steps ...
RUN pip install flash-attn --no-build-isolation
```
Note: Build takes 10-30 minutes. Fixed in v0.4.2+.

### Pod OOMKilled during model loading
Model loading requires ~40-50GB RAM. If pod is killed immediately without error logs, check memory limit.

**Fix**: Set memory limit to 64Gi in your deployment:
```yaml
resources:
  limits:
    memory: 64Gi
    nvidia.com/gpu: 1
  requests:
    memory: 32Gi
```

### Triton JIT compilation fails - missing C compiler
If you see `Failed to find C compiler. Please specify via CC environment variable`:
```
RuntimeError: Failed to find C compiler. Please specify via CC environment variable or set triton.knobs.build.impl.
```
**Fix**: Add `build-essential` to Dockerfile. Fixed in v0.4.2+.

### libnuma.so.1 missing
If you see `ImportError: libnuma.so.1: cannot open shared object file`, the `libnuma1` package is missing. This is required by sgl_kernel for GPU operations. Fixed in v0.4.1+.

### Version pinning does not work
SGLang, diffusers, and transformers must be installed from git main branch. Pinned versions (e.g., sglang v0.5.8) fail to run with GLM-Image.

## License

MIT License (GLM-Image model license applies to generated content)
