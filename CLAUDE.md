# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GLM-Image Server using SGLang - a Docker container that serves the [GLM-Image](https://huggingface.co/zai-org/GLM-Image) diffusion model with OpenAI-compatible API endpoints.

## Commands

### Build and run
```bash
docker build -t glm-image-sglang .
docker run --gpus all -p 30000:30000 -v ./models:/app/models glm-image-sglang

# With local model
docker run --gpus all -p 30000:30000 \
  -e MODEL_PATH=/app/models/GLM-Image \
  -v ./models:/app/models \
  glm-image-sglang
```

### Save/load Docker image
```bash
docker save glm-image-sglang -o glm-image-sglang.tar
docker load -i glm-image-sglang.tar
```

### Test the API
```bash
# Text-to-image (all params)
curl http://localhost:30000/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{
    "model": "zai-org/GLM-Image",
    "prompt": "A sunset with text \"Hello\" in the sky",
    "size": "1024x1024",
    "n": 1,
    "response_format": "b64_json",
    "num_inference_steps": 50,
    "guidance_scale": 1.5,
    "seed": 42
  }'

# Image-to-image (all params)
curl -X POST http://localhost:30000/v1/images/edits \
  -F "model=zai-org/GLM-Image" \
  -F "image=@input.jpg" \
  -F "prompt=Add a rainbow" \
  -F "size=1024x1024" \
  -F "n=1" \
  -F "response_format=b64_json" \
  -F "num_inference_steps=50" \
  -F "guidance_scale=1.5" \
  -F "seed=42"

# Health check
curl http://localhost:30000/health

# List models
curl http://localhost:30000/v1/models

# Test inside container
docker exec -it <container_id> bash
curl http://localhost:30000/health
```

### Using OpenAI Python Client
```python
from openai import OpenAI
import base64

client = OpenAI(base_url="http://localhost:30000/v1", api_key="not-needed")

response = client.images.generate(
    model="zai-org/GLM-Image",
    prompt='A robot painting with the text "Art by AI" on canvas',
    size="1024x1024",
    response_format="b64_json"
)

with open("output.png", "wb") as f:
    f.write(base64.b64decode(response.data[0].b64_json))
```

## Architecture

Single-container setup:
- **Dockerfile** - CUDA 12.4 base, installs SGLang + transformers + diffusers from git, includes curl and vim
- **SGLang server** - Port 30000, OpenAI-compatible API

## API Parameters

### `/v1/images/generations` (Text-to-Image)
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `prompt` | string | required | Text description (use quotes for text to render) |
| `model` | string | zai-org/GLM-Image | Model ID |
| `size` | string | 1024x1024 | Dimensions (divisible by 32) |
| `n` | int | 1 | Number of images (1-4) |
| `response_format` | string | b64_json | `b64_json` or `url` |
| `num_inference_steps` | int | 50 | Diffusion steps |
| `guidance_scale` | float | 1.5 | Prompt adherence |
| `seed` | int | random | For reproducibility |

### `/v1/images/edits` (Image-to-Image)
Same parameters as above, plus:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `image` | file | required | Input image |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL_PATH` | zai-org/GLM-Image | HuggingFace model ID or local path |
| `HF_HOME` | /app/models | Model cache directory |
| `HF_TOKEN` | - | HuggingFace token if needed |

## Tips

- **Text rendering**: Enclose text in quotation marks in your prompt (e.g., `"Hello World"`)
- **Dimensions**: Must be divisible by 32 (e.g., 1024x1024, 1152x896, 896x1152)
- **Quality**: Increase `num_inference_steps` (50-100) for better results
- **Reproducibility**: Use same `seed` value to get identical outputs

## Requirements

- NVIDIA GPU with 24GB+ VRAM (40GB+ recommended)
- Docker with nvidia-docker2
- CUDA 12.4 compatible driver
