"""FastAPI chat-server — broker ↔ Browser SSE multiplex.

Endpoints (B-222 plan):
  GET  /health           — Task 4
  GET  /chat/history     — Task 5
  GET  /chat/peers       — Task 6
  POST /chat/send        — Task 7
  GET  /chat/stream      — Task 9 (SSE)
  GET  /                 — Task 10 (static UI)
"""
from __future__ import annotations

import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI

from tools.chat_server.broker_client import BrokerClient

logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))
logger = logging.getLogger("chat-server")

broker = BrokerClient()


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"chat-server starting; broker_url={broker.url}")
    yield
    logger.info("chat-server stopping")


app = FastAPI(title="EBS Chat Server", lifespan=lifespan)


@app.get("/health")
async def health():
    """Placeholder — Task 4 will replace with full impl."""
    return {"status": "ok"}
