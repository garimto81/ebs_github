"""Resilience tests — broker SPOF recovery.

Run:
  pytest tools/chat_server/tests/test_resilience.py -v -m resilience

Scenarios:
  1. broker kill + restart → WAL durability + sentinel preserved
  2. SSE client disconnect → server detects + does not hang

Notes:
  - 본 test 는 broker 를 실제로 stop/start 하므로 다른 broker-dependent test
    와 병렬 실행 금지. CI 미포함.
"""
from __future__ import annotations

import asyncio
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone

import httpx
import pytest

from tools.chat_server.broker_client import BrokerClient


BROKER_URL = os.environ.get("BROKER_URL", "http://127.0.0.1:7383/mcp")
CHAT_SERVER_URL = os.environ.get("CHAT_SERVER_URL", "http://localhost:7390")
REPO_ROOT = os.environ.get("EBS_REPO_ROOT", "C:/claude/ebs")


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _broker_alive_sync() -> bool:
    """Check broker via start_message_bus.py --probe (JSON output, alive=true)."""
    try:
        r = subprocess.run(
            [sys.executable, "tools/orchestrator/start_message_bus.py", "--probe"],
            capture_output=True,
            text=True,
            timeout=5,
            cwd=REPO_ROOT,
        )
    except Exception:
        return False
    # probe exits 0 if alive, 1 if not. Parse stdout JSON for robustness.
    try:
        data = json.loads(r.stdout)
        return bool(data.get("alive"))
    except (ValueError, TypeError):
        # Fallback: exit code 0 = alive
        return r.returncode == 0


@pytest.fixture(scope="module")
def broker_initially_alive():
    if not _broker_alive_sync():
        pytest.skip("broker must be alive at module start")


@pytest.mark.resilience
def test_broker_kill_and_restart(broker_initially_alive):
    """broker SIGTERM → restart 후 동작 회복 + WAL sentinel 보존."""
    # 1. 사전 publish (state 보존 검증용)
    asyncio.run(
        BrokerClient(url=BROKER_URL).publish(
            topic="chat:room:design",
            payload={
                "kind": "msg",
                "from": "S2",
                "to": [],
                "body": "before-restart sentinel",
                "mentions": [],
                "reply_to": None,
                "thread_id": None,
                "ts": _now_iso(),
            },
            source="S2",
        )
    )

    # 2. broker stop
    subprocess.run(
        [sys.executable, "tools/orchestrator/stop_message_bus.py"],
        cwd=REPO_ROOT,
        timeout=10,
        capture_output=True,
    )
    time.sleep(2)

    # 3. broker dead 확인
    assert not _broker_alive_sync(), "broker should be dead after stop"

    # 4. broker restart
    subprocess.run(
        [sys.executable, "tools/orchestrator/start_message_bus.py", "--detach"],
        cwd=REPO_ROOT,
        timeout=15,
        capture_output=True,
    )
    time.sleep(3)

    # 5. broker alive 복구
    assert _broker_alive_sync(), "broker should be alive after restart"

    # 6. history 에 sentinel 보존 (WAL durability)
    r = asyncio.run(
        BrokerClient(url=BROKER_URL).get_history(
            topic="chat:room:design", limit=50
        )
    )
    events = r.get("events", []) or []
    sentinels = [
        e
        for e in events
        if isinstance(e, dict)
        and isinstance(e.get("payload"), dict)
        and e["payload"].get("body") == "before-restart sentinel"
    ]
    assert len(sentinels) >= 1, "sentinel message lost across broker restart"


@pytest.mark.resilience
@pytest.mark.asyncio
async def test_sse_client_disconnect_detected():
    """SSE client 가 끊었을 때 server 가 is_disconnected 감지 (서버 무한 hang X).

    chat-server live 필요.
    """
    try:
        async with httpx.AsyncClient(timeout=2.0) as http:
            r = await http.get(f"{CHAT_SERVER_URL}/health")
            if r.status_code != 200:
                pytest.skip("chat-server not running")
    except Exception:
        pytest.skip("chat-server not reachable")

    # 짧은 SSE connection 후 close
    async with httpx.AsyncClient(timeout=5.0) as http:
        async with http.stream(
            "GET", f"{CHAT_SERVER_URL}/chat/stream?from_seq=0"
        ) as r:
            await asyncio.sleep(1)
            # implicit close on context exit

    # health 가 200 유지 — server hang X 검증
    async with httpx.AsyncClient(timeout=2.0) as http:
        r = await http.get(f"{CHAT_SERVER_URL}/health")
        assert r.status_code == 200
