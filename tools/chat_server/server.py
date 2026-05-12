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

import asyncio
import json
import logging
import os
import re
from contextlib import asynccontextmanager
from datetime import datetime, timezone, timedelta

from pathlib import Path

import httpx
from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from sse_starlette.sse import EventSourceResponse

from tools.chat_server.broker_client import BrokerClient
from tools.chat_server.models import SendRequest

UI_DIR = Path(__file__).parent / "ui"

MENTION_RE = re.compile(r"@([A-Za-z][\w-]*)")


def _parse_mentions(body: str) -> list[str]:
    return [f"@{m}" for m in MENTION_RE.findall(body)]

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

app.mount("/static", StaticFiles(directory=UI_DIR), name="static")


@app.get("/")
async def root():
    return FileResponse(UI_DIR / "index.html")


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


@app.post("/chat/send")
async def chat_send(req: SendRequest):
    """User-initiated chat send. source is hardcoded 'user'."""
    topic = f"chat:{req.channel}"
    mentions = req.mentions or _parse_mentions(req.body)
    kind = "reply" if req.reply_to is not None else "msg"
    payload = {
        "kind": kind,
        "from": "user",
        "to": [m.lstrip("@") for m in mentions],
        "body": req.body,
        "reply_to": req.reply_to,
        "thread_id": req.thread_id,
        "mentions": mentions,
        "ts": datetime.now(timezone.utc).isoformat(),
    }
    try:
        r = await broker.publish(topic=topic, payload=payload, source="user")
    except Exception as e:
        logger.exception("broker publish failed")
        raise HTTPException(status_code=503, detail=f"broker error: {e}")
    return r


@app.get("/chat/stream")
async def chat_stream(request: Request, from_seq: int = 0):
    """SSE multiplex — subscribes to all topics, emits chat:* and stream:*/cascade:* separately.

    Frontend distinguishes by `event:` field:
      event: chat       — chat:room:* / chat:dm:* / chat:thread:*
      event: trace      — stream:* / cascade:* / pipeline:* / audit:* (LIVE TRACE 분할)
      event: error      — broker error (UI 빨간 배너)
    """
    async def event_gen():
        last_seq = from_seq
        backoff = 1.0
        while True:
            if await request.is_disconnected():
                logger.info("SSE client disconnected")
                break
            try:
                r = await broker.subscribe(
                    topic="*", from_seq=last_seq, timeout_sec=30
                )
                backoff = 1.0  # reset on success
                for event in r.get("events", []):
                    last_seq = max(last_seq, event["seq"]) + 0
                    topic = event.get("topic", "")
                    ev_type = "chat" if topic.startswith("chat:") else "trace"
                    yield {"event": ev_type, "data": json.dumps(event)}
                last_seq = r.get("next_seq", last_seq)
            except StopAsyncIteration:
                # mock side_effect exhausted in tests
                break
            except Exception as e:
                logger.warning(f"broker subscribe error: {e}; backing off {backoff}s")
                yield {"event": "error", "data": json.dumps({"error": str(e)})}
                await asyncio.sleep(backoff)
                backoff = min(backoff * 5, 30.0)

    return EventSourceResponse(event_gen())
