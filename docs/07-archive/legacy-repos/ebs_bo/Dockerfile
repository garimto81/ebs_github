# ═══════════════════════════════════════════
# EBS Back Office — Multi-stage Dockerfile
# ═══════════════════════════════════════════
# Stages:
#   dev  — uvicorn --reload, editable install
#   prod — uvicorn, frozen dependencies

# ── Base ──────────────────────────────────
FROM python:3.12-slim AS base

WORKDIR /app
ENV PYTHONPATH=/app/src \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ── Development ───────────────────────────
FROM base AS dev

RUN pip install --no-cache-dir pytest pytest-asyncio httpx

COPY src/ src/
COPY tests/ tests/

# Port is configured via BO_PORT env var (default 8080)
CMD ["sh", "-c", "uvicorn bo.main:app --host 0.0.0.0 --port ${BO_PORT:-8080} --reload --reload-dir /app/src"]

# ── Production ────────────────────────────
FROM base AS prod

COPY src/ src/

CMD ["sh", "-c", "uvicorn bo.main:app --host 0.0.0.0 --port ${BO_PORT:-8080} --workers 2"]
