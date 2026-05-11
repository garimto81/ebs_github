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

import httpx
from fastapi import FastAPI

from tools.chat_server.broker_client import BrokerClient

logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))
logger = logging.getLogger("chat-server")

VERSION = "0.1.0"

broker = BrokerClient()


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"chat-server starting; broker_url={broker.url}")
    yield
    logger.info("chat-server stopping")


app = FastAPI(title="EBS Chat Server", lifespan=lifespan)


@app.get("/health")
async def health():
    """Health probe — broker connectivity included (non-blocking)."""
    broker_alive = False
    try:
        async with httpx.AsyncClient(timeout=1.0) as http:
            # broker MCP endpoint serves 4xx without proper handshake,
            # but TCP-level reachability is what we want here.
            r = await http.get(broker.url.replace("/mcp", "/"))
            broker_alive = r.status_code < 500
    except Exception:
        broker_alive = False
    return {
        "status": "ok",
        "version": VERSION,
        "broker_url": broker.url,
        "broker_alive": broker_alive,
    }
