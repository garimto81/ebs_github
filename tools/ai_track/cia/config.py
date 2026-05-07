"""CIA Engine config — Ollama models, thresholds, paths."""
from __future__ import annotations

import os
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
TOOLS = REPO / "tools"

# Ollama
OLLAMA_BASE = os.environ.get("CIA_OLLAMA_URL", "http://localhost:11434")
OLLAMA_GENERATE = f"{OLLAMA_BASE}/api/generate"
OLLAMA_TAGS = f"{OLLAMA_BASE}/api/tags"

# Models (defaults match installed Ollama on this host)
INTENT_MODEL = os.environ.get("CIA_INTENT_MODEL", "gemma4:latest")  # 8B fast classifier
CIA_MODEL = os.environ.get("CIA_VERIFY_MODEL", "gemma4:latest")     # 8B default for speed; gemma4:26b for accuracy
EMBED_MODEL = os.environ.get("CIA_EMBED_MODEL", "bge-m3")

# Confidence thresholds
CONFIDENCE_AUTO_APPLY = float(os.environ.get("CIA_CONF_AUTO", "0.90"))
CONFIDENCE_REVIEW = float(os.environ.get("CIA_CONF_REVIEW", "0.55"))

# Limits
MAX_DIFF_LINES = int(os.environ.get("CIA_MAX_DIFF", "5000"))
MAX_CANDIDATES = int(os.environ.get("CIA_MAX_CAND", "30"))
MAX_CASCADE_DEPTH = int(os.environ.get("CIA_MAX_DEPTH", "3"))
LLM_TIMEOUT_SEC = int(os.environ.get("CIA_LLM_TIMEOUT", "120"))
LLM_RETRY = int(os.environ.get("CIA_LLM_RETRY", "2"))

# Existing infra
DOC_DISCOVERY = TOOLS / "doc_discovery.py"
DOC_RAG = TOOLS / "doc_rag.py"

# Ignored paths (no cascade)
IGNORE_PATTERNS = [
    "docs/_generated/",
    "docs/3. Change Requests/",
    ".cache/",
    "node_modules/",
    ".dart_tool/",
    "build/",
]
