# GLM-Image Server (SGLang)

Docker-based server for [GLM-Image](https://huggingface.co/zai-org/GLM-Image) using SGLang with **OpenAI-compatible API**.

## Requirements

- Docker with NVIDIA GPU support (nvidia-docker2)
- NVIDIA GPU with 24GB+ VRAM (40GB+ recommended)
- CUDA 12.4 compatible driver

## Quick Start

### 1. Build the Docker image

```bash
docker build -t glm-image-sglang .
```

### 2. Run the server

```bash
# Download model from HuggingFace on first run
docker run --gpus all -p 30000:30000 -v ./models:/app/models glm-image-sglang

# Or use a local model path
docker run --gpus all -p 30000:30000 \
  -e MODEL_PATH=/app/models/GLM-Image \
  -v ./models:/app/models \
  glm-image-sglang
```

### 3. Access the API

- API: http://localhost:30000
- Endpoints: `/v1/images/generations`, `/v1/images/edits`, `/v1/models`

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

## Working Examples

### Text-to-Image (Basic)

```bash
curl http://localhost:30000/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A beautiful sunset over mountains",
    "size": "1024x1024",
    "response_format": "b64_json"
  }' | python3 -c "import sys, json, base64; open('output.png', 'wb').write(base64.b64decode(json.load(sys.stdin)['data'][0]['b64_json']))"
```

### Text-to-Image (All Parameters)

```bash
curl http://localhost:30000/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{
    "model": "zai-org/GLM-Image",
    "prompt": "A futuristic cityscape with the text \"Welcome to 2050\" on a billboard",
    "size": "1152x896",
    "n": 1,
    "response_format": "b64_json",
    "num_inference_steps": 75,
    "guidance_scale": 1.5,
    "seed": 42
  }' | python3 -c "import sys, json, base64; open('output.png', 'wb').write(base64.b64decode(json.load(sys.stdin)['data'][0]['b64_json']))"
```

### Image-to-Image (Basic)

```bash
curl -X POST http://localhost:30000/v1/images/edits \
  -F "image=@input.jpg" \
  -F "prompt=Replace the background with a space station" \
  -F "response_format=b64_json" \
  | python3 -c "import sys, json, base64; open('edited.png', 'wb').write(base64.b64decode(json.load(sys.stdin)['data'][0]['b64_json']))"
```

### Image-to-Image (All Parameters)

```bash
curl -X POST http://localhost:30000/v1/images/edits \
  -F "model=zai-org/GLM-Image" \
  -F "image=@input.jpg" \
  -F "prompt=Transform into a watercolor painting style" \
  -F "size=1024x1024" \
  -F "n=1" \
  -F "response_format=b64_json" \
  -F "num_inference_steps=50" \
  -F "guidance_scale=1.5" \
  -F "seed=42" \
  | python3 -c "import sys, json, base64; open('edited.png', 'wb').write(base64.b64decode(json.load(sys.stdin)['data'][0]['b64_json']))"
```

### List Models

```bash
curl http://localhost:30000/v1/models
```

### Health Check

```bash
curl http://localhost:30000/health
```

### Using OpenAI Python Client

```python
from openai import OpenAI
import base64

client = OpenAI(
    base_url="http://localhost:30000/v1",
    api_key="not-needed"
)

# Text-to-Image
response = client.images.generate(
    model="zai-org/GLM-Image",
    prompt='A robot painting with the text "Art by AI" on canvas',
    size="1024x1024",
    n=1,
    response_format="b64_json"
)

image_data = base64.b64decode(response.data[0].b64_json)
with open("generated.png", "wb") as f:
    f.write(image_data)
```

### Test Inside Container

```bash
# Enter container
docker exec -it <container_id> bash

# Test text-to-image
curl http://localhost:30000/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{"prompt": "A cat", "size": "512x512", "response_format": "b64_json"}'

# Check health
curl http://localhost:30000/health
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL_PATH` | zai-org/GLM-Image | Model path (HuggingFace ID or local path) |
| `HF_HOME` | /app/models | Model cache directory |
| `HF_TOKEN` | - | HuggingFace token (if model requires auth) |

## Tips

- **Text rendering**: Enclose text in quotation marks in your prompt (e.g., `"Hello World"`)
- **Dimensions**: Must be divisible by 32 (e.g., 1024x1024, 1152x896, 896x1152)
- **Quality**: Increase `num_inference_steps` (50-100) for better results
- **Reproducibility**: Use same `seed` value to get identical outputs
- **VRAM**: Model requires ~24-40GB VRAM

## License

MIT License (GLM-Image model license applies to generated content)
