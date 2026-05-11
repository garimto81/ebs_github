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
from datetime import datetime, timezone, timedelta

import httpx
from fastapi import FastAPI, HTTPException, Query

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


@app.get("/chat/history")
async def chat_history(
    channel: str = Query(..., description="Channel suffix (e.g. 'room:design')"),
    since_seq: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
):
    """Catch-up history for a single channel."""
    topic = f"chat:{channel}"
    try:
        r = await broker.get_history(topic=topic, since_seq=since_seq, limit=limit)
    except Exception as e:
        logger.exception("broker get_history failed")
        raise HTTPException(status_code=503, detail=f"broker error: {e}")
    return r


@app.get("/chat/peers")
async def chat_peers(active: bool = Query(False)):
    """Active sessions (recent publishers).

    active=true → last_seen within 5 minutes filter.
    """
    try:
        r = await broker.discover_peers()
    except Exception as e:
        logger.exception("broker discover_peers failed")
        raise HTTPException(status_code=503, detail=f"broker error: {e}")

    peers = r.get("peers", [])
    if active:
        cutoff = datetime.now(timezone.utc) - timedelta(minutes=5)
        filtered = []
        for p in peers:
            try:
                ts = datetime.fromisoformat(p["last_seen"].replace("Z", "+00:00"))
                if ts >= cutoff:
                    filtered.append(p)
            except (KeyError, ValueError):
                continue
        peers = filtered
    return {"peers": peers, "count": len(peers)}
