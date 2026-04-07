# ──────────────────────────────────────────────
# ClosetGenius FastAPI backend
# Runs Florence-2 (GPU) + Groq Llama chat
# ──────────────────────────────────────────────
FROM pytorch/pytorch:2.3.0-cuda12.1-cudnn8-runtime

WORKDIR /app

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 libsm6 libxrender1 libxext6 \
    && rm -rf /var/lib/apt/lists/*

# Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-download Florence-2 weights at build time so startup is fast
RUN python - <<'EOF'
import sys, types, importlib.machinery
mock = types.ModuleType("flash_attn")
mock.__spec__ = importlib.machinery.ModuleSpec("flash_attn", None)
for m in ["flash_attn","flash_attn.flash_attn_interface","flash_attn.bert_padding","flash_attn.flash_attn_utils"]:
    sys.modules[m] = mock
from transformers import AutoProcessor, AutoModelForCausalLM
AutoModelForCausalLM.from_pretrained("microsoft/Florence-2-base", trust_remote_code=True, attn_implementation="eager")
AutoProcessor.from_pretrained("microsoft/Florence-2-base", trust_remote_code=True)
print("Florence-2 cached.")
EOF

COPY main.py .

EXPOSE 8080

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
