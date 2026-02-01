# GLM-Image Server (SGLang)

Docker-based server for [GLM-Image](https://huggingface.co/zai-org/GLM-Image) using SGLang with **OpenAI-compatible API**.

Tested on **NVIDIA H20 GPUs**. OpenShift compatible - runs as non-root user with arbitrary UID support.

## Requirements

- Docker with NVIDIA GPU support (nvidia-docker2)
- NVIDIA GPU with 24GB+ VRAM (H20, H100, A100, or similar)
- CUDA 12.4+ compatible driver
- 64GB+ system RAM for model loading

## Quick Start

### 1. Build the Docker image

```bash
./build.sh
# Creates: glm-image-sglang:<git-tag>
```

### 2. Run the server

```bash
docker run --gpus all -p 30000:30000 \
  -e MODEL_PATH=/app/models/GLM-Image \
  -v ./models:/app/models \
  glm-image-sglang:v0.4.4
```

### 3. Access the API

- API: http://localhost:30000
- Endpoints: `/v1/images/generations`, `/v1/images/edits`, `/v1/models`

## Load from tar (offline deployment)

```bash
docker load -i glm-image-sglang-v0.4.4.tar
docker run --gpus all -p 30000:30000 \
  -e MODEL_PATH=/app/models/GLM-Image \
  -v ./models:/app/models \
  glm-image-sglang:v0.4.4
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/v1/images/generations` | POST | Text-to-image generation |
| `/v1/images/edits` | POST | Image-to-image editing |
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
  -F "image=@input.jpg" \
  -F "prompt=Replace the background with a snow forest" \
  -F "response_format=b64_json" \
  | python3 -c "import sys, json, base64; open('edited.png', 'wb').write(base64.b64decode(json.load(sys.stdin)['data'][0]['b64_json']))"
```

> **Note**: Image editing may have issues in some SGLang versions. If you get a `RuntimeError: Model generation returned no output`, try updating SGLang or use text-to-image generation instead.

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

with open("input.jpg", "rb") as f:
    files = {"image": ("input.jpg", f, "image/jpeg")}
    data = {
        "model": "zai-org/GLM-Image",
        "prompt": "Replace the background with a snow forest",
        "response_format": "b64_json"
    }
    response = requests.post(f"{BASE_URL}/v1/images/edits", files=files, data=data, timeout=600)

if response.status_code == 200:
    result = response.json()
    img_bytes = base64.b64decode(result["data"][0]["b64_json"])
    with open("edited.png", "wb") as f:
        f.write(img_bytes)
    print("Edited image saved to edited.png")
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
| `MODEL_PATH` | (required) | Local path to GLM-Image model |
| `HF_HOME` | /app/models | Model cache directory |
| `HF_TOKEN` | - | HuggingFace token (if needed) |

## Tips

- **Text rendering**: Enclose text in quotation marks in your prompt (e.g., `"Hello World"`)
- **Dimensions**: Must be divisible by 32 (e.g., 1024x1024, 1152x896, 896x1152)
- **Quality**: Increase `num_inference_steps` (50-100) for better results
- **Reproducibility**: Use same `seed` value to get identical outputs

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
