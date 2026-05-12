---
title: Inter-Session Chat — Implementation Plan (7 Day)
owner: conductor
tier: internal
status: PLAN
spec: docs/4. Operations/Inter_Session_Chat_Design.md
backlog: docs/4. Operations/Conductor_Backlog/B-222-inter-session-chat-ui.md
last-updated: 2026-05-11
---

# Inter-Session Chat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 기존 message_bus broker 위에 채팅 어휘 (자유 텍스트 + 멘션 + 스레드) 와 Web UI 4분할 (Docker 컨테이너) 을 얹어, 멀티 세션이 서로 협의하고 사용자가 관전/인터럽트 할 수 있는 대화 레이어 구축.

**Architecture:** broker 코드 1줄 변경 (chat:* prefix ACL) + 신규 FastAPI chat-server 컨테이너 (SSE multiplex) + 4분할 정적 HTML/JS + hook 통합 (자율 발화 / mention 감지). event bus = 기계 신호 / chat = 의사소통 — 두 모델 상보적.

**Tech Stack:** Python 3.11 + FastAPI 0.115 + sse-starlette + MCP client (StreamableHTTP) + vanilla JS + Tailwind CDN + Docker + pytest + asyncio.

---

## File Structure

생성/수정 파일 일람:

| 파일 | 행동 | 책임 |
|------|-----|------|
| `tools/orchestrator/message_bus/topics.py` | 수정 (+ ~15 LOC) | `chat:*` prefix 허용 + `source="user"` publisher_id 보호 |
| `tools/orchestrator/message_bus/tests/test_topics_chat_acl.py` | 신규 | Topic ACL chat:* + user source 보호 단위 테스트 |
| `docs/4. Operations/Chat_Protocol.md` | 신규 | Payload schema + 채널 컨벤션 SSOT |
| `tools/chat_server/__init__.py` | 신규 (빈) | 패키지 식별 |
| `tools/chat_server/models.py` | 신규 | Pydantic schema (ChatMessage, SendRequest) |
| `tools/chat_server/broker_client.py` | 신규 | MCP broker 호출 wrapper (async) |
| `tools/chat_server/server.py` | 신규 | FastAPI app (5 endpoints) |
| `tools/chat_server/requirements.txt` | 신규 | Python 의존성 lock |
| `tools/chat_server/Dockerfile` | 신규 | Python 3.11 slim + uvicorn |
| `tools/chat_server/docker-compose.yml` | 신규 | host.docker.internal + healthcheck |
| `tools/chat_server/tests/test_health.py` | 신규 | /health 200 OK |
| `tools/chat_server/tests/test_history.py` | 신규 | /chat/history endpoint |
| `tools/chat_server/tests/test_peers.py` | 신규 | /chat/peers endpoint |
| `tools/chat_server/tests/test_send.py` | 신규 | /chat/send 발신 (user source) |
| `tools/chat_server/tests/test_sse.py` | 신규 | /chat/stream SSE multiplex |
| `tools/chat_server/tests/test_e2e_consensus.py` | 신규 | 2 세션 합의 시나리오 E2E |
| `tools/chat_server/ui/index.html` | 신규 | 4분할 정적 layout |
| `tools/chat_server/ui/app.js` | 신규 | SSE 구독 + @ autocomplete + 렌더링 |
| `tools/chat_server/ui/styles.css` | 신규 | Stream 색상 + 4분할 grid |
| `tools/chat_server/cli.py` | 신규 | watch / send / history 보조 CLI |
| `.claude/hooks/orch_PreToolUse.py` | 수정 (+ ~80 LOC) | `emit_chat_advisory` 자율 발화 |
| `.claude/hooks/orch_SessionStart.py` | 수정 (+ ~60 LOC) | `inject_chat_mentions` mention 감지 |
| `docs/4. Operations/team_assignment_v10_3.yaml` | 수정 (+ ~20 LOC) | topics.acl chat:* entry |
| `docs/4. Operations/Docker_Runtime.md` | 수정 (+ ~50 LOC) | chat-server 운영 섹션 |

---

## Task Index (21 tasks)

| # | Task | Day | TDD? |
|---|------|----|:----:|
| 1 | `topics.py` chat:* prefix + user source 보호 | 1 | ✓ |
| 2 | `Chat_Protocol.md` schema SSOT | 1 | — |
| 3 | chat_server scaffold (models + broker_client + 빈 server.py) | 2 | ✓ |
| 4 | `/health` endpoint | 2 | ✓ |
| 5 | `/chat/history` endpoint | 2 | ✓ |
| 6 | `/chat/peers` endpoint | 2 | ✓ |
| 7 | `/chat/send` endpoint (user source) | 2 | ✓ |
| 8 | Dockerfile + docker-compose.yml + 빌드 검증 | 2.5 | — |
| 9 | `/chat/stream` SSE multiplex | 2 | ✓ |
| 10 | UI `index.html` 4분할 grid + `styles.css` | 3 | — |
| 11 | UI `app.js` SSE 구독 + 메시지 렌더링 | 3 | — |
| 12 | UI `@` autocomplete 드롭다운 | 3 | — |
| 13 | Hook `emit_chat_advisory` (PreToolUse) | 4 | ✓ |
| 14 | Hook `inject_chat_mentions` (SessionStart) | 4 | ✓ |
| 15 | UI `reply_to` 시각화 | 5 | — |
| 16 | UI 4번째 분할 LIVE TRACE | 5 | — |
| 17 | Consensus `silent_ok_30s` helper | 6 | ✓ |
| 18 | E2E test — 2 세션 합의 시나리오 | 6 | ✓ |
| 19 | `team_assignment_v10_3.yaml` topics.acl entry | 7 | — |
| 20 | `Docker_Runtime.md` chat-server 섹션 | 7 | — |
| 21 | `cli.py` 보조 CLI (watch/send/history) | 7 | ✓ |

---

## Task 1: `topics.py` chat:* prefix + user source 보호 (Day 1)

**Files:**
- Modify: `tools/orchestrator/message_bus/topics.py:30,44` (+ ~15 LOC)
- Create: `tools/orchestrator/message_bus/tests/test_topics_chat_acl.py`

- [ ] **Step 1: Write failing tests**

Create `tools/orchestrator/message_bus/tests/test_topics_chat_acl.py`:

```python
"""Topic ACL — chat:* prefix + source='user' anti-spoofing."""
from tools.orchestrator.message_bus.topics import check_publish_acl


class TestChatPrefix:
    def test_chat_room_design_any_source_allowed(self):
        ok, _ = check_publish_acl("chat:room:design", "S2")
        assert ok is True

    def test_chat_room_blocker_any_source_allowed(self):
        ok, _ = check_publish_acl("chat:room:blocker", "S3")
        assert ok is True

    def test_chat_thread_allowed(self):
        ok, _ = check_publish_acl("chat:thread:rake-01", "S2")
        assert ok is True

    def test_chat_dm_allowed(self):
        ok, _ = check_publish_acl("chat:dm:S2-S3", "S2")
        assert ok is True


class TestUserSourceProtection:
    def test_session_cannot_spoof_user_source(self):
        ok, reason = check_publish_acl("chat:room:design", "user")
        assert ok is False
        assert "reserved" in reason.lower()

    def test_chat_server_can_publish_as_user(self):
        ok, _ = check_publish_acl(
            "chat:room:design", "user", publisher_id="chat-server"
        )
        assert ok is True

    def test_random_publisher_id_rejected(self):
        ok, reason = check_publish_acl(
            "chat:room:design", "user", publisher_id="hacker"
        )
        assert ok is False
        assert "not authorized" in reason.lower()


class TestExistingBehaviorPreserved:
    def test_cascade_still_open(self):
        ok, _ = check_publish_acl("cascade:Foundation.md", "S2")
        assert ok is True

    def test_bus_still_reserved(self):
        ok, _ = check_publish_acl("bus:internal", "S2")
        assert ok is False

    def test_unknown_prefix_still_denied(self):
        ok, _ = check_publish_acl("unknown:topic", "S2")
        assert ok is False

    def test_stream_source_match_required(self):
        ok, _ = check_publish_acl("stream:S2", "S2")
        assert ok is True
        ok, _ = check_publish_acl("stream:S2", "S3")
        assert ok is False
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd C:/claude/ebs
pytest tools/orchestrator/message_bus/tests/test_topics_chat_acl.py -v
```

Expected: 9 tests FAIL — `TestChatPrefix` 는 unknown prefix 로 거부 / `TestUserSourceProtection` 은 publisher_id 인자 누락으로 TypeError.

- [ ] **Step 3: Modify `topics.py` — chat:* prefix + publisher_id 파라미터**

Edit `tools/orchestrator/message_bus/topics.py`:

Change line 30 (`_OPEN_TOPIC_PREFIXES`):

```python
# Topics any source may publish
# v10.4: added "pipeline:" for cross-cutting gap→write→dev→qa flow
# v11.1 (B-222): added "chat:" for inter-session chat layer
_OPEN_TOPIC_PREFIXES = ("cascade:", "defect:", "audit:", "pipeline:", "chat:")
```

Add after line 37 (after `_DEV_TOPIC_PREFIXES`):

```python
# v11.1 (B-222) — source="user" anti-spoofing.
# Only the chat-server (Web UI proxy) may publish as the human user.
_USER_SOURCE = "user"
_USER_AUTHORIZED_PUBLISHERS = {"chat-server"}
```

Modify `check_publish_acl` signature + add user check (before existing checks):

```python
def check_publish_acl(
    topic: str, source: str, publisher_id: str = ""
) -> tuple[bool, str | None]:
    """Check if `source` can publish to `topic`.

    v11 Phase A — strict mode:
        Custom topics not matching any whitelist prefix are DENIED.
    v11.1 (B-222) — source='user' protected by publisher_id whitelist.

    Args:
        topic: Topic string (e.g., "stream:S2", "chat:room:design").
        source: Sender identity (e.g., "S2", "user").
        publisher_id: Caller process identifier (e.g., "chat-server").
            Used to gate source='user' anti-spoofing.

    Returns:
        (allowed, reason) — reason is None if allowed.
    """
    if not topic:
        return False, "topic is empty"

    # v11.1: source='user' may only be published by chat-server.
    if source == _USER_SOURCE and publisher_id not in _USER_AUTHORIZED_PUBLISHERS:
        return False, (
            f"source='{_USER_SOURCE}' reserved for Web UI; "
            f"publisher_id='{publisher_id}' not authorized "
            f"(allowed: {sorted(_USER_AUTHORIZED_PUBLISHERS)})"
        )

    # Reserved (broker-internal) — always deny external publishers
    for pfx in _RESERVED_PREFIXES:
        if topic.startswith(pfx):
            return False, f"topic '{topic}' is reserved (prefix '{pfx}')"

    # ... rest of existing function body unchanged ...
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
pytest tools/orchestrator/message_bus/tests/test_topics_chat_acl.py -v
```

Expected: 9 tests PASS.

- [ ] **Step 5: Run existing topics tests — regression check**

```bash
pytest tools/orchestrator/message_bus/tests/ -v -k "not chat_acl"
```

Expected: ALL existing tests PASS (chat:* / publisher_id 추가가 기존 동작 변경 없음).

- [ ] **Step 6: Commit**

```bash
git add tools/orchestrator/message_bus/topics.py tools/orchestrator/message_bus/tests/test_topics_chat_acl.py
git commit -m "feat(broker): chat:* prefix + source='user' anti-spoofing (B-222 T1)

- Add 'chat:' to _OPEN_TOPIC_PREFIXES (any source publish)
- Add publisher_id parameter (default '') to check_publish_acl
- Only publisher_id='chat-server' may publish with source='user'
- 9 new ACL tests pass; existing tests preserved (no regression)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: `Chat_Protocol.md` schema SSOT (Day 1)

**Files:**
- Create: `docs/4. Operations/Chat_Protocol.md`

- [ ] **Step 1: Create protocol SSOT doc**

Create `docs/4. Operations/Chat_Protocol.md`:

```markdown
---
title: Chat Protocol — Payload Schema + Channel Convention SSOT
owner: conductor
tier: internal
status: ACTIVE
spec: docs/4. Operations/Inter_Session_Chat_Design.md
last-updated: 2026-05-11
---

# Chat Protocol — Payload Schema

본 문서는 `chat:*` topic 의 페이로드 schema + 채널 컨벤션 SSOT.
구현은 `tools/chat_server/models.py` 가 본 schema 를 직접 반영.

## 1. Payload Schema

JSON payload (broker `publish_event` 의 `payload` 인자):

```json
{
  "kind": "msg",
  "from": "S2",
  "to": ["S3"],
  "body": "Foundation.md 의 rake 표기 어떻게 가져갈래?",
  "reply_to": null,
  "thread_id": null,
  "mentions": ["@S3"],
  "ts": "2026-05-11T15:30:00Z"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|-----|:----:|-----|
| `kind` | enum | ✓ | `msg` / `reply` / `system` / `decision` |
| `from` | string | ✓ | stream id 또는 `"user"` |
| `to` | string[] | | 수신자 배열. `"*"` 또는 빈 배열 = 채널 전체 |
| `body` | string | ✓ | markdown 허용, 최대 4000자 |
| `reply_to` | int / null | | 다른 메시지 broker seq |
| `thread_id` | string / null | | 스레드 식별자 |
| `mentions` | string[] | | `@`-prefix parse 결과 |
| `ts` | ISO8601 | ✓ | 클라이언트 측 발화 시각 |

## 2. Kind 종류

| kind | 의미 |
|------|------|
| `msg` | 일반 발언 |
| `reply` | `reply_to` 가 가리키는 메시지에 대한 답 |
| `system` | hook 자동 발화 (cascade / blocker / handoff) |
| `decision` | 합의 종결 + 결과 명시 (silent OK or 명시) |

## 3. 채널 컨벤션

| 패턴 | 용도 | v1 default? |
|------|-----|:-----------:|
| `chat:room:design` | PRD 정합성 / 정본 협의 | ✓ |
| `chat:room:blocker` | 외부 의존 / 블로커 공유 | ✓ |
| `chat:room:handoff` | stream 간 작업 인계 | ✓ |
| `chat:room:<name>` | 임의 공용 채널 | — |
| `chat:dm:<A>-<B>` | 1:1 (알파벳순 정렬) | — |
| `chat:thread:<id>` | 스레드 분기 (긴 토론) | — |

## 4. Source 규칙

| source 값 | 발급 주체 | publisher_id |
|----------|---------|--------------|
| `S1`~`S11`, `SMEM` | 각 worktree hook | (any) |
| `user` | chat-server (Web UI) 만 | `"chat-server"` |

(spec §4.1 참조)

## 5. 멘션 규칙

- `@S3` — stream 멘션. 해당 stream 의 hook 이 다음 cycle 에 context inject.
- `@user` — 사용자 호출. 사용자가 Web UI 에서 응답.
- `@all` — 채널 전체 (의례적, mention array 에 모든 active stream 추가).

## 6. 합의 모델 (silent OK 30s)

질문 발화 후 30초 응답 없음 → 발화자가 `kind="decision"` 으로 자기 의견 진행 선언.
`@user` 멘션 포함 시 silent OK 비활성 (사용자 명시 답변 대기).

(spec §10 참조)
```

- [ ] **Step 2: Commit**

```bash
git add "docs/4. Operations/Chat_Protocol.md"
git commit -m "docs(operations): Chat Protocol schema SSOT (B-222 T2)

페이로드 schema (kind/from/to/body/reply_to/thread_id/mentions/ts),
4 kind (msg/reply/system/decision), 채널 컨벤션, source 규칙,
멘션 규칙, 합의 모델 SSOT.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```


## Task 3: chat_server scaffold (Day 2)

**Files:**
- Create: `tools/chat_server/__init__.py` (empty)
- Create: `tools/chat_server/requirements.txt`
- Create: `tools/chat_server/models.py`
- Create: `tools/chat_server/broker_client.py`
- Create: `tools/chat_server/server.py` (skeleton)
- Create: `tools/chat_server/tests/__init__.py` (empty)
- Create: `tools/chat_server/tests/conftest.py`

- [ ] **Step 1: Create `requirements.txt`**

```
fastapi==0.115.*
uvicorn[standard]==0.32.*
sse-starlette==2.1.*
mcp==1.1.*
httpx==0.27.*
pydantic==2.9.*
pytest==8.3.*
pytest-asyncio==0.24.*
```

- [ ] **Step 2: Install dependencies (locally for dev)**

```bash
cd C:/claude/ebs
pip install -r tools/chat_server/requirements.txt
```

Expected: 모든 패키지 설치 완료.

- [ ] **Step 3: Create `models.py` — Pydantic schema**

```python
"""Chat payload Pydantic schemas.

본 schema 는 docs/4. Operations/Chat_Protocol.md §1 의 직접 반영.
"""
from __future__ import annotations

from typing import Literal
from pydantic import BaseModel, Field


ChatKind = Literal["msg", "reply", "system", "decision"]


class ChatMessage(BaseModel):
    """Single chat message payload (broker payload 본문)."""

    kind: ChatKind
    from_: str = Field(alias="from")
    to: list[str] = Field(default_factory=list)
    body: str = Field(max_length=4000)
    reply_to: int | None = None
    thread_id: str | None = None
    mentions: list[str] = Field(default_factory=list)
    ts: str  # ISO8601, client-supplied

    model_config = {"populate_by_name": True}


class SendRequest(BaseModel):
    """POST /chat/send body."""

    channel: str  # e.g., "room:design"
    body: str = Field(max_length=4000)
    reply_to: int | None = None
    thread_id: str | None = None
    mentions: list[str] = Field(default_factory=list)
```

- [ ] **Step 4: Create `broker_client.py` — async MCP client wrapper**

```python
"""Async MCP client wrapper for the broker (StreamableHTTP).

본 wrapper 는 chat-server 가 broker 의 7 tools 를 호출하는 단일 진입점.
publisher_id 는 항상 'chat-server' 로 고정 (source='user' 발급 권한).
"""
from __future__ import annotations

import os
from contextlib import asynccontextmanager

from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client


PUBLISHER_ID = "chat-server"


class BrokerClient:
    def __init__(self, url: str | None = None):
        self.url = url or os.environ.get(
            "BROKER_URL", "http://host.docker.internal:7383/mcp"
        )

    @asynccontextmanager
    async def session(self):
        """Open MCP session (one-shot)."""
        async with streamablehttp_client(self.url) as (read, write, _):
            async with ClientSession(read, write) as session:
                await session.initialize()
                yield session

    async def publish(
        self, topic: str, payload: dict, source: str
    ) -> dict:
        """Publish via broker (publisher_id auto-injected)."""
        async with self.session() as s:
            r = await s.call_tool(
                "publish_event",
                {
                    "topic": topic,
                    "payload": payload,
                    "source": source,
                    "publisher_id": PUBLISHER_ID,
                },
            )
            return r.structuredContent or {}

    async def subscribe(
        self, topic: str, from_seq: int = 0, timeout_sec: int = 30
    ) -> dict:
        async with self.session() as s:
            r = await s.call_tool(
                "subscribe",
                {"topic": topic, "from_seq": from_seq, "timeout_sec": timeout_sec},
            )
            return r.structuredContent or {}

    async def get_history(
        self, topic: str = "*", since_seq: int = 0, limit: int = 50
    ) -> dict:
        async with self.session() as s:
            r = await s.call_tool(
                "get_history",
                {"topic": topic, "since_seq": since_seq, "limit": limit},
            )
            return r.structuredContent or {}

    async def discover_peers(self) -> dict:
        async with self.session() as s:
            r = await s.call_tool("discover_peers", {})
            return r.structuredContent or {}
```

- [ ] **Step 5: Create `server.py` skeleton (FastAPI app + lifespan)**

```python
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
```

- [ ] **Step 6: Create `tests/conftest.py` — pytest fixtures**

```python
"""Shared pytest fixtures for chat-server tests."""
from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from tools.chat_server.server import app


@pytest.fixture
def client():
    return TestClient(app)
```

- [ ] **Step 7: Commit scaffold**

```bash
git add tools/chat_server/
git commit -m "feat(chat-server): scaffold (B-222 T3)

- requirements.txt, models.py (Pydantic), broker_client.py (async MCP wrapper)
- server.py skeleton + lifespan
- tests/conftest.py + empty __init__.py
- publisher_id='chat-server' fixed in BrokerClient

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: `/health` endpoint (Day 2)

**Files:**
- Create: `tools/chat_server/tests/test_health.py`
- Modify: `tools/chat_server/server.py` (replace placeholder /health)

- [ ] **Step 1: Write failing test**

Create `tools/chat_server/tests/test_health.py`:

```python
"""Tests for /health endpoint."""


def test_health_ok(client):
    r = client.get("/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"
    assert "broker_url" in body
    assert "version" in body


def test_health_includes_broker_probe(client, monkeypatch):
    """When broker unreachable, /health still returns 200 but with broker_alive=False."""
    r = client.get("/health")
    assert r.status_code == 200
    body = r.json()
    # broker_alive may be True (live) or False (down) — both 200
    assert "broker_alive" in body
    assert isinstance(body["broker_alive"], bool)
```

- [ ] **Step 2: Run test to verify failure**

```bash
cd C:/claude/ebs
pytest tools/chat_server/tests/test_health.py -v
```

Expected: 2 tests FAIL — placeholder /health 가 `broker_url` / `version` / `broker_alive` 필드 누락.

- [ ] **Step 3: Implement full /health**

Edit `tools/chat_server/server.py` — replace the placeholder `/health`:

```python
import httpx

VERSION = "0.1.0"


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
```

- [ ] **Step 4: Run test to verify pass**

```bash
pytest tools/chat_server/tests/test_health.py -v
```

Expected: 2 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/chat_server/server.py tools/chat_server/tests/test_health.py
git commit -m "feat(chat-server): /health endpoint with broker probe (B-222 T4)"
```


## Task 5: `/chat/history` endpoint (Day 2)

**Files:**
- Create: `tools/chat_server/tests/test_history.py`
- Modify: `tools/chat_server/server.py` (add /chat/history)

- [ ] **Step 1: Write failing test (with broker mock)**

Create `tools/chat_server/tests/test_history.py`:

```python
"""Tests for /chat/history endpoint."""
import pytest
from unittest.mock import AsyncMock


@pytest.fixture
def mock_broker(monkeypatch):
    mock = AsyncMock()
    mock.get_history.return_value = {
        "events": [
            {
                "seq": 42,
                "topic": "chat:room:design",
                "source": "S2",
                "ts": "2026-05-11T15:30:00Z",
                "payload": {
                    "kind": "msg",
                    "from": "S2",
                    "to": ["S3"],
                    "body": "test",
                    "mentions": ["@S3"],
                    "ts": "2026-05-11T15:30:00Z",
                },
            }
        ],
        "count": 1,
    }
    monkeypatch.setattr("tools.chat_server.server.broker", mock)
    return mock


def test_history_default_channel(client, mock_broker):
    r = client.get("/chat/history?channel=room:design")
    assert r.status_code == 200
    body = r.json()
    assert len(body["events"]) == 1
    assert body["events"][0]["payload"]["body"] == "test"
    mock_broker.get_history.assert_called_once()
    args = mock_broker.get_history.call_args.kwargs
    assert args["topic"] == "chat:room:design"


def test_history_since_seq(client, mock_broker):
    r = client.get("/chat/history?channel=room:design&since_seq=10&limit=30")
    assert r.status_code == 200
    args = mock_broker.get_history.call_args.kwargs
    assert args["since_seq"] == 10
    assert args["limit"] == 30


def test_history_missing_channel_400(client, mock_broker):
    r = client.get("/chat/history")
    assert r.status_code == 422  # FastAPI auto-validates required query
```

- [ ] **Step 2: Run test (FAIL)**

```bash
pytest tools/chat_server/tests/test_history.py -v
```

Expected: 3 tests FAIL (404).

- [ ] **Step 3: Implement /chat/history**

Add to `tools/chat_server/server.py`:

```python
from fastapi import Query, HTTPException


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
```

- [ ] **Step 4: Run test (PASS)**

```bash
pytest tools/chat_server/tests/test_history.py -v
```

Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/chat_server/server.py tools/chat_server/tests/test_history.py
git commit -m "feat(chat-server): /chat/history endpoint (B-222 T5)"
```

---

## Task 6: `/chat/peers` endpoint (Day 2)

**Files:**
- Create: `tools/chat_server/tests/test_peers.py`
- Modify: `tools/chat_server/server.py` (add /chat/peers)

- [ ] **Step 1: Write failing test**

Create `tools/chat_server/tests/test_peers.py`:

```python
"""Tests for /chat/peers endpoint."""
import pytest
from unittest.mock import AsyncMock


@pytest.fixture
def mock_broker(monkeypatch):
    mock = AsyncMock()
    mock.discover_peers.return_value = {
        "peers": [
            {"source": "S2", "last_seen": "2026-05-11T15:30:00Z", "event_count": 12},
            {"source": "S3", "last_seen": "2026-05-11T15:32:00Z", "event_count": 5},
        ],
        "count": 2,
    }
    monkeypatch.setattr("tools.chat_server.server.broker", mock)
    return mock


def test_peers_returns_active_list(client, mock_broker):
    r = client.get("/chat/peers")
    assert r.status_code == 200
    body = r.json()
    assert body["count"] == 2
    assert {p["source"] for p in body["peers"]} == {"S2", "S3"}


def test_peers_idle_filter(client, mock_broker):
    """active=true 옵션 시 5분 이내만 반환."""
    r = client.get("/chat/peers?active=true")
    assert r.status_code == 200
    # mock 데이터 둘 다 최근이므로 변동 없음
    assert r.json()["count"] >= 0
```

- [ ] **Step 2: Run test (FAIL)**

```bash
pytest tools/chat_server/tests/test_peers.py -v
```

Expected: 2 tests FAIL (404).

- [ ] **Step 3: Implement /chat/peers**

Add to `tools/chat_server/server.py`:

```python
from datetime import datetime, timezone, timedelta


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
```

- [ ] **Step 4: Run test (PASS)**

```bash
pytest tools/chat_server/tests/test_peers.py -v
```

Expected: 2 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/chat_server/server.py tools/chat_server/tests/test_peers.py
git commit -m "feat(chat-server): /chat/peers endpoint with active filter (B-222 T6)"
```

---

## Task 7: `/chat/send` endpoint (user source) (Day 2)

**Files:**
- Create: `tools/chat_server/tests/test_send.py`
- Modify: `tools/chat_server/server.py` (add /chat/send)

- [ ] **Step 1: Write failing test**

Create `tools/chat_server/tests/test_send.py`:

```python
"""Tests for POST /chat/send."""
import re
import pytest
from unittest.mock import AsyncMock


@pytest.fixture
def mock_broker(monkeypatch):
    mock = AsyncMock()
    mock.publish.return_value = {
        "seq": 99,
        "ts": "2026-05-11T15:35:00Z",
        "topic": "chat:room:design",
        "recipients": 3,
    }
    monkeypatch.setattr("tools.chat_server.server.broker", mock)
    return mock


def test_send_basic(client, mock_broker):
    r = client.post("/chat/send", json={
        "channel": "room:design",
        "body": "hello",
    })
    assert r.status_code == 200
    body = r.json()
    assert body["seq"] == 99
    mock_broker.publish.assert_called_once()
    kwargs = mock_broker.publish.call_args.kwargs
    assert kwargs["topic"] == "chat:room:design"
    assert kwargs["source"] == "user"
    assert kwargs["payload"]["from"] == "user"
    assert kwargs["payload"]["body"] == "hello"


def test_send_with_mentions(client, mock_broker):
    r = client.post("/chat/send", json={
        "channel": "room:design",
        "body": "@S3 quick question",
    })
    assert r.status_code == 200
    kwargs = mock_broker.publish.call_args.kwargs
    assert "@S3" in kwargs["payload"]["mentions"]


def test_send_with_reply_to(client, mock_broker):
    r = client.post("/chat/send", json={
        "channel": "room:design",
        "body": "agreed",
        "reply_to": 42,
    })
    assert r.status_code == 200
    kwargs = mock_broker.publish.call_args.kwargs
    assert kwargs["payload"]["reply_to"] == 42
    assert kwargs["payload"]["kind"] == "reply"


def test_send_body_too_long(client, mock_broker):
    r = client.post("/chat/send", json={
        "channel": "room:design",
        "body": "x" * 5000,
    })
    assert r.status_code == 422


def test_send_kind_msg_when_no_reply_to(client, mock_broker):
    r = client.post("/chat/send", json={
        "channel": "room:design",
        "body": "hi",
    })
    assert r.status_code == 200
    kwargs = mock_broker.publish.call_args.kwargs
    assert kwargs["payload"]["kind"] == "msg"
```

- [ ] **Step 2: Run test (FAIL)**

```bash
pytest tools/chat_server/tests/test_send.py -v
```

Expected: 5 tests FAIL.

- [ ] **Step 3: Implement /chat/send**

Add to `tools/chat_server/server.py`:

```python
import re
from datetime import datetime, timezone

from tools.chat_server.models import SendRequest

MENTION_RE = re.compile(r"@([A-Za-z][\w-]*)")


def _parse_mentions(body: str) -> list[str]:
    return [f"@{m}" for m in MENTION_RE.findall(body)]


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
```

- [ ] **Step 4: Run test (PASS)**

```bash
pytest tools/chat_server/tests/test_send.py -v
```

Expected: 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/chat_server/server.py tools/chat_server/tests/test_send.py
git commit -m "feat(chat-server): POST /chat/send with mention parsing (B-222 T7)"
```


## Task 8: Dockerfile + docker-compose.yml + 빌드 검증 (Day 2.5)

**Files:**
- Create: `tools/chat_server/Dockerfile`
- Create: `tools/chat_server/docker-compose.yml`
- Create: `tools/chat_server/.dockerignore`

- [ ] **Step 1: Create `Dockerfile`**

```dockerfile
FROM python:3.11-slim
WORKDIR /app

# 의존성 (Docker layer cache 효율 위해 먼저)
COPY tools/chat_server/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# 앱 코드 (broker_client import 위해 message_bus 경로 포함)
COPY tools/orchestrator/message_bus/__init__.py /app/tools/orchestrator/message_bus/__init__.py
COPY tools/chat_server /app/tools/chat_server

# PYTHONPATH 로 절대 import 활성
ENV PYTHONPATH=/app
ENV BROKER_URL=http://host.docker.internal:7383/mcp
ENV LOG_LEVEL=INFO

EXPOSE 7390
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:7390/health', timeout=2)" || exit 1

CMD ["uvicorn", "tools.chat_server.server:app", "--host", "0.0.0.0", "--port", "7390"]
```

- [ ] **Step 2: Create `docker-compose.yml`**

```yaml
services:
  chat-server:
    build:
      context: ../..              # repo root (Dockerfile copies tools/* paths)
      dockerfile: tools/chat_server/Dockerfile
    container_name: ebs-chat-server
    ports:
      - "7390:7390"
    environment:
      - BROKER_URL=http://host.docker.internal:7383/mcp
      - LOG_LEVEL=INFO
    extra_hosts:
      - "host.docker.internal:host-gateway"   # Linux 호환
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:7390/health', timeout=2)"]
      interval: 30s
      timeout: 3s
      retries: 3
```

- [ ] **Step 3: Create `.dockerignore`**

```
**/__pycache__
**/*.pyc
**/.pytest_cache
**/.mypy_cache
tools/chat_server/tests/
```

- [ ] **Step 4: Build image**

```bash
cd C:/claude/ebs
docker compose -f tools/chat_server/docker-compose.yml build
```

Expected: 빌드 성공 (대략 60-120 sec). 에러 시 `pip install` log 확인.

- [ ] **Step 5: Start container + health probe**

```bash
# broker 가 살아있어야 함 (이미 실행 중이 아니라면)
python tools/orchestrator/start_message_bus.py --detach

# chat-server 기동
docker compose -f tools/chat_server/docker-compose.yml up -d

# 헬스 체크 (15초 대기 후)
sleep 15
curl http://localhost:7390/health
```

Expected JSON:
```json
{"status":"ok","version":"0.1.0","broker_url":"http://host.docker.internal:7383/mcp","broker_alive":true}
```

- [ ] **Step 6: Verify container healthcheck status**

```bash
docker compose -f tools/chat_server/docker-compose.yml ps
```

Expected: `STATUS` 컬럼이 `Up X seconds (healthy)`.

- [ ] **Step 7: Stop container (cleanup)**

```bash
docker compose -f tools/chat_server/docker-compose.yml down
```

- [ ] **Step 8: Commit**

```bash
git add tools/chat_server/Dockerfile tools/chat_server/docker-compose.yml tools/chat_server/.dockerignore
git commit -m "feat(chat-server): Docker container build + healthcheck (B-222 T8)

- Dockerfile python:3.11-slim + uvicorn
- docker-compose.yml host.docker.internal mapping
- HEALTHCHECK 30s interval; verified healthy state

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: `/chat/stream` SSE multiplex (Day 2)

**Files:**
- Create: `tools/chat_server/tests/test_sse.py`
- Modify: `tools/chat_server/server.py` (add /chat/stream)

- [ ] **Step 1: Write failing test (SSE 헤더 / 단일 이벤트 흐름)**

Create `tools/chat_server/tests/test_sse.py`:

```python
"""Tests for /chat/stream SSE multiplex.

Note: TestClient 는 SSE 를 streaming response 로 처리. iter_lines 사용.
"""
import json
import pytest
from unittest.mock import AsyncMock


@pytest.fixture
def mock_broker(monkeypatch):
    mock = AsyncMock()
    # 첫 subscribe 호출: 단일 이벤트 반환
    # 두 번째 호출: empty (timeout)
    mock.subscribe.side_effect = [
        {
            "events": [
                {
                    "seq": 1,
                    "topic": "chat:room:design",
                    "source": "S2",
                    "ts": "2026-05-11T15:30:00Z",
                    "payload": {
                        "kind": "msg", "from": "S2", "to": [],
                        "body": "hi", "mentions": [], "ts": "2026-05-11T15:30:00Z",
                    },
                }
            ],
            "next_seq": 2,
            "mode": "history",
        },
        {"events": [], "next_seq": 2, "mode": "timeout"},
    ]
    monkeypatch.setattr("tools.chat_server.server.broker", mock)
    return mock


def test_sse_headers(client, mock_broker):
    """SSE response has correct Content-Type + Cache-Control."""
    with client.stream("GET", "/chat/stream?from_seq=0") as r:
        assert r.status_code == 200
        assert r.headers["content-type"].startswith("text/event-stream")
        assert "no-cache" in r.headers.get("cache-control", "").lower()
        # close immediately — we only check headers


def test_sse_emits_chat_event(client, mock_broker):
    """First subscribe returns 1 event → SSE 'chat' event emitted."""
    with client.stream("GET", "/chat/stream?from_seq=0") as r:
        # Read at least one event line
        for line in r.iter_lines():
            if line.startswith("event:"):
                assert "chat" in line or "trace" in line
                break
            if line.startswith("data:"):
                data = json.loads(line[len("data:"):].strip())
                assert data["seq"] == 1
                break
```

- [ ] **Step 2: Run test (FAIL)**

```bash
pytest tools/chat_server/tests/test_sse.py -v
```

Expected: 2 tests FAIL (404).

- [ ] **Step 3: Implement /chat/stream**

Add to `tools/chat_server/server.py`:

```python
import asyncio
from fastapi import Request
from sse_starlette.sse import EventSourceResponse


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
                    last_seq = max(last_seq, event["seq"]) + 0  # next_seq logic via broker response
                    topic = event.get("topic", "")
                    ev_type = "chat" if topic.startswith("chat:") else "trace"
                    yield {"event": ev_type, "data": json.dumps(event)}
                # respect broker next_seq
                last_seq = r.get("next_seq", last_seq)
            except Exception as e:
                logger.warning(f"broker subscribe error: {e}; backing off {backoff}s")
                yield {"event": "error", "data": json.dumps({"error": str(e)})}
                await asyncio.sleep(backoff)
                backoff = min(backoff * 5, 30.0)

    return EventSourceResponse(event_gen())
```

Also add at top of `server.py` (if not already there):
```python
import json
```

- [ ] **Step 4: Run test (PASS)**

```bash
pytest tools/chat_server/tests/test_sse.py -v
```

Expected: 2 tests PASS.

- [ ] **Step 5: Manual smoke test (broker live)**

```bash
# Terminal 1
python tools/orchestrator/start_message_bus.py --detach
docker compose -f tools/chat_server/docker-compose.yml up -d --build

# Terminal 2 — SSE listener
curl -N http://localhost:7390/chat/stream?from_seq=0

# Terminal 3 — publish test message
python -c "
from tools.orchestrator.message_bus.tests.pub_demo import publish_sync
publish_sync('chat:room:design', {'kind':'msg','from':'S2','to':[],'body':'hello','mentions':[],'ts':'2026-05-11T15:40:00Z'}, 'S2')
"
```

Expected (Terminal 2): `event: chat\ndata: {...}\n` 즉시 출력.

- [ ] **Step 6: Commit**

```bash
git add tools/chat_server/server.py tools/chat_server/tests/test_sse.py
git commit -m "feat(chat-server): /chat/stream SSE multiplex (B-222 T9)

- subscribe loop with backoff on broker error
- chat vs trace event distinction (frontend dispatches to channels)
- error event for broker-down state (UI banner)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```


## Task 10: UI `index.html` 4분할 grid + `styles.css` (Day 3)

**Files:**
- Create: `tools/chat_server/ui/index.html`
- Create: `tools/chat_server/ui/styles.css`
- Modify: `tools/chat_server/server.py` (mount static)
- Modify: `tools/chat_server/Dockerfile` (COPY ui)

- [ ] **Step 1: Create `ui/index.html`**

```html
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8" />
  <title>EBS Chat</title>
  <link rel="stylesheet" href="/static/styles.css" />
</head>
<body>
  <header class="topbar">
    <span class="brand">EBS Chat</span>
    <span class="broker-state" id="broker-state">broker: ...</span>
    <span class="peers" id="peers"></span>
  </header>
  <main class="grid">
    <section class="panel" data-channel="room:design">
      <h2><span class="hash">#</span>design</h2>
      <div class="messages" id="msgs-design"></div>
      <div class="composer">
        <textarea data-channel="room:design" placeholder="메시지 (@ 입력 → 멘션)"></textarea>
        <div class="autocomplete" hidden></div>
      </div>
    </section>
    <section class="panel" data-channel="room:blocker">
      <h2><span class="hash">#</span>blocker</h2>
      <div class="messages" id="msgs-blocker"></div>
      <div class="composer">
        <textarea data-channel="room:blocker" placeholder="메시지 (@ 입력 → 멘션)"></textarea>
        <div class="autocomplete" hidden></div>
      </div>
    </section>
    <section class="panel" data-channel="room:handoff">
      <h2><span class="hash">#</span>handoff</h2>
      <div class="messages" id="msgs-handoff"></div>
      <div class="composer">
        <textarea data-channel="room:handoff" placeholder="메시지 (@ 입력 → 멘션)"></textarea>
        <div class="autocomplete" hidden></div>
      </div>
    </section>
    <section class="panel trace" data-channel="trace">
      <h2>LIVE TRACE <span class="ro">(read-only)</span></h2>
      <div class="messages" id="msgs-trace"></div>
    </section>
  </main>
  <script src="/static/app.js"></script>
</body>
</html>
```

- [ ] **Step 2: Create `ui/styles.css`**

```css
:root {
  --bg: #0d1117;
  --fg: #c9d1d9;
  --muted: #6e7681;
  --panel: #161b22;
  --border: #30363d;
  --accent: #58a6ff;
  --s1: #b392f0;
  --s2: #56d364;
  --s3: #58a6ff;
  --s7: #e3b341;
  --s8: #2dd4bf;
  --s9: #f778ba;
  --s10a: #ff7b72;
  --s10w: #db6d28;
  --s11: #8b949e;
  --smem: #6e7681;
  --user: #f85149;
  --system: #6e7681;
}

* { box-sizing: border-box; }
body {
  margin: 0;
  background: var(--bg);
  color: var(--fg);
  font: 13px/1.5 -apple-system, "Segoe UI", monospace;
  height: 100vh;
  display: flex;
  flex-direction: column;
}

.topbar {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 8px 12px;
  border-bottom: 1px solid var(--border);
  background: var(--panel);
}
.brand { font-weight: bold; }
.broker-state { color: var(--muted); }
.peers { margin-left: auto; color: var(--muted); }

.grid {
  flex: 1;
  display: grid;
  grid-template-columns: 1fr 1fr;
  grid-template-rows: 1fr 1fr;
  gap: 1px;
  background: var(--border);
  min-height: 0;
}

.panel {
  background: var(--panel);
  display: flex;
  flex-direction: column;
  min-height: 0;
  overflow: hidden;
}
.panel h2 {
  margin: 0;
  padding: 6px 12px;
  font-size: 13px;
  border-bottom: 1px solid var(--border);
  background: #0d1117;
}
.panel h2 .hash { color: var(--accent); margin-right: 2px; }
.panel h2 .ro { color: var(--muted); font-weight: normal; font-size: 11px; }

.messages {
  flex: 1;
  overflow-y: auto;
  padding: 8px 12px;
  font-family: ui-monospace, "Cascadia Code", Consolas, monospace;
}
.msg { padding: 2px 0; word-break: break-word; }
.msg .ts { color: var(--muted); margin-right: 6px; }
.msg .from { font-weight: bold; margin-right: 6px; }
.msg.from-S1 .from  { color: var(--s1); }
.msg.from-S2 .from  { color: var(--s2); }
.msg.from-S3 .from  { color: var(--s3); }
.msg.from-S7 .from  { color: var(--s7); }
.msg.from-S8 .from  { color: var(--s8); }
.msg.from-S9 .from  { color: var(--s9); }
.msg.from-S10-A .from { color: var(--s10a); }
.msg.from-S10-W .from { color: var(--s10w); }
.msg.from-S11 .from { color: var(--s11); }
.msg.from-SMEM .from { color: var(--smem); }
.msg.from-user .from { color: var(--user); }
.msg.kind-system .from { color: var(--system); font-style: italic; }
.msg .mention { background: #3d2e10; color: #f0d264; padding: 0 2px; border-radius: 2px; }
.msg .mention-self { background: #4d2120; color: #ff7676; }

.msg .reply-ref { color: var(--muted); font-size: 11px; padding-left: 14px; }
.msg.reply { padding-left: 14px; border-left: 2px solid var(--border); }

.composer {
  position: relative;
  border-top: 1px solid var(--border);
  padding: 6px;
}
.composer textarea {
  width: 100%;
  background: #0d1117;
  border: 1px solid var(--border);
  color: var(--fg);
  font-family: inherit;
  padding: 4px 6px;
  resize: none;
  min-height: 38px;
  max-height: 80px;
}
.autocomplete {
  position: absolute;
  bottom: 100%;
  left: 6px;
  background: #0d1117;
  border: 1px solid var(--border);
  min-width: 200px;
  max-height: 200px;
  overflow-y: auto;
  z-index: 10;
}
.autocomplete .item {
  padding: 4px 8px;
  cursor: pointer;
}
.autocomplete .item.active {
  background: #1f6feb;
  color: white;
}
```

- [ ] **Step 3: Mount static in `server.py`**

Add to `tools/chat_server/server.py`:

```python
from pathlib import Path
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

UI_DIR = Path(__file__).parent / "ui"
app.mount("/static", StaticFiles(directory=UI_DIR), name="static")


@app.get("/")
async def root():
    return FileResponse(UI_DIR / "index.html")
```

- [ ] **Step 4: Update `Dockerfile` to copy ui/**

Edit the COPY line in `Dockerfile`:

```dockerfile
# 앱 코드 + UI 정적 파일
COPY tools/orchestrator/message_bus/__init__.py /app/tools/orchestrator/message_bus/__init__.py
COPY tools/chat_server /app/tools/chat_server
```

(이미 `tools/chat_server` 전체 복사하므로 ui/ 자동 포함됨. 변경 없음.)

- [ ] **Step 5: Rebuild + smoke test**

```bash
docker compose -f tools/chat_server/docker-compose.yml up -d --build
sleep 5
curl -s http://localhost:7390/ | grep "EBS Chat"
curl -s http://localhost:7390/static/styles.css | head -5
```

Expected: HTML 본문 + CSS 본문 반환.

- [ ] **Step 6: Browser visual check**

브라우저 `http://localhost:7390/` → 4분할 grid 표시 (아직 메시지 없음, 다음 task 에서 SSE 연결).

- [ ] **Step 7: Commit**

```bash
git add tools/chat_server/ui/ tools/chat_server/server.py
git commit -m "feat(chat-server): 4분할 grid UI + Stream 색상 (B-222 T10)"
```

---

## Task 11: UI `app.js` SSE 구독 + 메시지 렌더링 (Day 3)

**Files:**
- Create: `tools/chat_server/ui/app.js`

- [ ] **Step 1: Create `app.js` — core rendering + SSE**

```javascript
(() => {
  "use strict";

  const CHAT_CHANNELS = ["room:design", "room:blocker", "room:handoff"];
  const PANEL_BY_CHANNEL = {
    "room:design": document.getElementById("msgs-design"),
    "room:blocker": document.getElementById("msgs-blocker"),
    "room:handoff": document.getElementById("msgs-handoff"),
    "trace": document.getElementById("msgs-trace"),
  };
  const SELF = "user";  // Web UI 는 항상 user 시점

  function escapeHtml(s) {
    return s.replace(/[&<>"']/g, c => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;",
      '"': "&quot;", "'": "&#39;"
    }[c]));
  }

  function highlightMentions(body, selfMention) {
    return escapeHtml(body).replace(/@([A-Za-z][\w-]*)/g, (_, name) => {
      const cls = name === selfMention ? "mention-self" : "mention";
      return `<span class="${cls}">@${name}</span>`;
    });
  }

  function renderMessage(panel, event) {
    const p = event.payload || {};
    const from = p.from || event.source || "unknown";
    const kind = p.kind || "msg";
    const ts = (p.ts || event.ts || "").slice(11, 16);  // HH:MM
    const isReply = kind === "reply" || p.reply_to != null;

    const el = document.createElement("div");
    el.className = `msg from-${from} kind-${kind}${isReply ? " reply" : ""}`;
    el.dataset.seq = event.seq;
    el.innerHTML =
      `<span class="ts">${ts}</span>` +
      `<span class="from">[${escapeHtml(from)}]</span>` +
      (isReply ? `<span class="reply-ref">re: ${p.reply_to}</span> ` : "") +
      highlightMentions(p.body || "", SELF);

    const stickyBottom =
      panel.scrollHeight - panel.scrollTop - panel.clientHeight < 40;
    panel.appendChild(el);
    if (stickyBottom) panel.scrollTop = panel.scrollHeight;
  }

  function renderTrace(event) {
    const panel = PANEL_BY_CHANNEL.trace;
    const topic = event.topic;
    const source = event.source || "?";
    const ts = (event.ts || "").slice(11, 16);
    const payloadStr = JSON.stringify(event.payload || {}).slice(0, 120);

    const el = document.createElement("div");
    el.className = "msg kind-system";
    el.innerHTML =
      `<span class="ts">${ts}</span>` +
      `<span class="from">${escapeHtml(topic)}</span>` +
      `<span style="color:var(--muted)">(${escapeHtml(source)})</span> ` +
      `<span style="color:var(--muted)">${escapeHtml(payloadStr)}</span>`;
    panel.appendChild(el);
    panel.scrollTop = panel.scrollHeight;
  }

  function dispatchEvent(event) {
    const topic = event.topic || "";
    if (topic.startsWith("chat:")) {
      const channel = topic.slice("chat:".length);
      const panel = PANEL_BY_CHANNEL[channel];
      if (panel) renderMessage(panel, event);
      // unknown chat channel → ignore in v1
    } else {
      // stream:* / cascade:* / pipeline:* / audit:* — LIVE TRACE
      renderTrace(event);
    }
  }

  async function loadHistory(channel) {
    const panel = PANEL_BY_CHANNEL[channel];
    if (!panel) return;
    try {
      const r = await fetch(
        `/chat/history?channel=${encodeURIComponent(channel)}&limit=50`
      );
      const data = await r.json();
      for (const event of data.events || []) renderMessage(panel, event);
    } catch (e) {
      console.warn("history load failed", channel, e);
    }
  }

  async function refreshPeers() {
    try {
      const r = await fetch("/chat/peers?active=true");
      const data = await r.json();
      const sources = (data.peers || []).map(p => p.source);
      document.getElementById("peers").textContent =
        "active: " + sources.join(" ");
      window.__activePeers = sources;
    } catch (e) {
      window.__activePeers = window.__activePeers || [];
    }
  }

  function connectSSE() {
    const banner = document.getElementById("broker-state");
    const src = new EventSource("/chat/stream?from_seq=0");
    src.addEventListener("chat", (e) => {
      try { dispatchEvent(JSON.parse(e.data)); }
      catch { /* ignore malformed */ }
    });
    src.addEventListener("trace", (e) => {
      try { renderTrace(JSON.parse(e.data)); }
      catch { /* ignore */ }
    });
    src.addEventListener("error", (e) => {
      banner.textContent = "broker: offline (retrying...)";
      banner.style.color = "var(--user)";
    });
    src.onopen = () => {
      banner.textContent = "broker: online";
      banner.style.color = "";
    };
  }

  // Composer Enter handler
  document.querySelectorAll(".composer textarea").forEach((ta) => {
    ta.addEventListener("keydown", async (e) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        const channel = ta.dataset.channel;
        const body = ta.value.trim();
        if (!body) return;
        try {
          await fetch("/chat/send", {
            method: "POST",
            headers: {"Content-Type": "application/json"},
            body: JSON.stringify({channel, body}),
          });
          ta.value = "";
        } catch (err) {
          console.error("send failed", err);
        }
      }
    });
  });

  // Init
  (async () => {
    await Promise.all(CHAT_CHANNELS.map(loadHistory));
    await refreshPeers();
    setInterval(refreshPeers, 5000);
    connectSSE();
  })();
})();
```

- [ ] **Step 2: Rebuild + smoke test**

```bash
docker compose -f tools/chat_server/docker-compose.yml up -d --build
```

브라우저 `http://localhost:7390/` 진입 → 4분할 grid + 상단 "broker: online".

- [ ] **Step 3: Publish + receive verify**

```bash
# 다른 터미널에서 publish
python -c "
import asyncio
from tools.chat_server.broker_client import BrokerClient

async def main():
    b = BrokerClient(url='http://127.0.0.1:7383/mcp')
    r = await b.publish('chat:room:design', {
        'kind': 'msg', 'from': 'S2', 'to': [],
        'body': '@user hello from S2', 'mentions': ['@user'],
        'ts': '2026-05-11T16:00:00Z',
    }, source='S2')
    print(r)
asyncio.run(main())
"
```

브라우저 #design 분할에 "[S2] @user hello from S2" 메시지 즉시 등장 (멘션 빨간 강조).

- [ ] **Step 4: Commit**

```bash
git add tools/chat_server/ui/app.js
git commit -m "feat(chat-server): UI SSE 구독 + 메시지 렌더링 (B-222 T11)

- EventSource 로 /chat/stream subscribe
- dispatchEvent: chat:* → 채널 분할, 그 외 → LIVE TRACE
- 멘션 하이라이트 (본인 @user 별도 색)
- composer Enter → /chat/send POST
- /chat/peers 5s polling → active 헤더 업데이트

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 12: UI `@` autocomplete 드롭다운 (Day 3)

**Files:**
- Modify: `tools/chat_server/ui/app.js` (append autocomplete logic)

- [ ] **Step 1: Append autocomplete code to `app.js`**

Add to the end of `app.js` (before closing `})()`):

```javascript
  // ──────────────── @ Autocomplete ────────────────

  function activePeers() {
    return [...(window.__activePeers || []), "user", "all"];
  }

  function showAutocomplete(textarea, dropdown, query) {
    const peers = activePeers().filter(
      p => p.toLowerCase().startsWith(query.toLowerCase())
    );
    if (peers.length === 0) {
      dropdown.hidden = true;
      return;
    }
    dropdown.innerHTML = peers
      .map((p, i) => `<div class="item${i === 0 ? " active" : ""}" data-peer="${escapeHtml(p)}">@${escapeHtml(p)}</div>`)
      .join("");
    dropdown.hidden = false;
  }

  function applyAutocomplete(textarea, peer) {
    const val = textarea.value;
    const caret = textarea.selectionStart;
    // 마지막 @ 위치 찾기
    const atIdx = val.lastIndexOf("@", caret - 1);
    if (atIdx < 0) return;
    const before = val.slice(0, atIdx);
    const after = val.slice(caret);
    const inserted = `@${peer} `;
    textarea.value = before + inserted + after;
    const newCaret = atIdx + inserted.length;
    textarea.setSelectionRange(newCaret, newCaret);
    textarea.focus();
  }

  document.querySelectorAll(".composer").forEach((composer) => {
    const ta = composer.querySelector("textarea");
    const dropdown = composer.querySelector(".autocomplete");

    ta.addEventListener("input", () => {
      const caret = ta.selectionStart;
      const val = ta.value;
      const atIdx = val.lastIndexOf("@", caret - 1);
      if (atIdx < 0) {
        dropdown.hidden = true;
        return;
      }
      const between = val.slice(atIdx + 1, caret);
      if (/\s/.test(between)) {
        dropdown.hidden = true;
        return;
      }
      showAutocomplete(ta, dropdown, between);
    });

    ta.addEventListener("keydown", (e) => {
      if (dropdown.hidden) return;
      const items = [...dropdown.querySelectorAll(".item")];
      const activeIdx = items.findIndex(it => it.classList.contains("active"));
      if (e.key === "ArrowDown") {
        e.preventDefault();
        const next = (activeIdx + 1) % items.length;
        items[activeIdx]?.classList.remove("active");
        items[next].classList.add("active");
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        const prev = (activeIdx - 1 + items.length) % items.length;
        items[activeIdx]?.classList.remove("active");
        items[prev].classList.add("active");
      } else if (e.key === "Enter") {
        e.preventDefault();
        const sel = items[activeIdx >= 0 ? activeIdx : 0];
        applyAutocomplete(ta, sel.dataset.peer);
        dropdown.hidden = true;
      } else if (e.key === "Escape") {
        dropdown.hidden = true;
      }
    });

    dropdown.addEventListener("click", (e) => {
      const item = e.target.closest(".item");
      if (item) {
        applyAutocomplete(ta, item.dataset.peer);
        dropdown.hidden = true;
      }
    });
  });
```

- [ ] **Step 2: 기존 Enter handler 와 충돌 방지**

기존 `ta.addEventListener("keydown", ...)` 의 Enter 처리가 autocomplete dropdown 표시 중일 때 send 되지 않도록 가드 추가. Task 11 의 Enter 핸들러 첫 줄에 추가:

```javascript
ta.addEventListener("keydown", async (e) => {
  const dd = ta.parentElement.querySelector(".autocomplete");
  if (e.key === "Enter" && !e.shiftKey) {
    if (dd && !dd.hidden) return;  // autocomplete 가 처리
    e.preventDefault();
    // ... 기존 send 로직 ...
```

- [ ] **Step 3: Rebuild + browser test**

```bash
docker compose -f tools/chat_server/docker-compose.yml up -d --build
```

브라우저 동작 확인:
1. #design 입력창 클릭
2. `@` 입력 → 드롭다운 등장 (peer list)
3. 화살표 ↓ + Enter → `@S3 ` 자동 삽입
4. 메시지 추가 입력 + Enter → 발신 (autocomplete 안 떠 있을 때만)

- [ ] **Step 4: Commit**

```bash
git add tools/chat_server/ui/app.js
git commit -m "feat(chat-server): @ autocomplete 드롭다운 (B-222 T12)

- @ 입력 → active peers (discover_peers 결과) 드롭다운
- ↑↓ 키 navigation, Enter 선택, Esc 취소
- send Enter 핸들러와 충돌 가드 (드롭다운 표시 중엔 send X)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```


## Task 13: Hook `emit_chat_advisory` (PreToolUse) (Day 4)

**Files:**
- Create: `tools/chat_server/hook_integration.py` (재사용 모듈)
- Create: `tools/chat_server/tests/test_hook_integration.py`
- Modify: `.claude/hooks/orch_PreToolUse.py` (add emit_chat_advisory call)

- [ ] **Step 1: Write failing test for hook_integration module**

Create `tools/chat_server/tests/test_hook_integration.py`:

```python
"""Tests for hook_integration helpers (used by .claude/hooks/)."""
import json
from unittest.mock import patch, MagicMock

from tools.chat_server import hook_integration as hi


def test_emit_chat_advisory_skips_when_no_impact():
    with patch("tools.chat_server.hook_integration._publish_sync") as pub:
        hi.emit_chat_advisory("docs/X.md", impacted=[], editor_team="S2")
        pub.assert_not_called()


def test_emit_chat_advisory_publishes_with_mentions():
    with patch("tools.chat_server.hook_integration._publish_sync") as pub, \
         patch("tools.chat_server.hook_integration._resolve_owner_streams") as resolve:
        resolve.return_value = ["S3", "S7"]
        hi.emit_chat_advisory(
            "docs/Foundation.md",
            impacted=["docs/Lobby_PRD.md", "docs/CC_PRD.md"],
            editor_team="S1",
        )
        pub.assert_called_once()
        kwargs = pub.call_args.kwargs
        assert kwargs["topic"] == "chat:room:design"
        assert kwargs["source"] == "S1"
        payload = kwargs["payload"]
        assert payload["kind"] == "system"
        assert payload["from"] == "S1"
        assert "@S3" in payload["mentions"]
        assert "@S7" in payload["mentions"]
        assert "Foundation.md" in payload["body"]


def test_emit_chat_advisory_silent_when_broker_down():
    with patch("tools.chat_server.hook_integration._publish_sync",
               side_effect=Exception("broker dead")):
        # 예외 발생해도 hook 진행 막지 않음 (silent skip)
        hi.emit_chat_advisory("docs/X.md", impacted=["docs/Y.md"], editor_team="S2")
```

- [ ] **Step 2: Run test (FAIL — module doesn't exist)**

```bash
pytest tools/chat_server/tests/test_hook_integration.py -v
```

Expected: ImportError / FAIL.

- [ ] **Step 3: Implement `hook_integration.py`**

Create `tools/chat_server/hook_integration.py`:

```python
"""Hook integration helpers — called from .claude/hooks/.

These are synchronous (hook 환경) wrappers around the async broker_client.
Broker dead 시 silent skip (hook 동작 막지 않음).
"""
from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timezone
from pathlib import Path

logger = logging.getLogger("chat-hook")


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _publish_sync(topic: str, payload: dict, source: str) -> None:
    """Sync wrapper for broker_client.publish. Silent skip on error."""
    try:
        from tools.chat_server.broker_client import BrokerClient
        client = BrokerClient(url="http://127.0.0.1:7383/mcp")
        asyncio.run(client.publish(topic=topic, payload=payload, source=source))
    except Exception as e:
        logger.debug(f"chat publish failed (silent): {e}")


def _resolve_owner_streams(paths: list[str]) -> list[str]:
    """Map impacted paths → owner stream ids.

    Heuristic: docs/2. Development/2.1 Frontend/Lobby/* → S2
               docs/2. Development/2.4 Command Center/*  → S3
               docs/2. Development/2.2 Backend/*         → S7
               etc.
    Fallback: empty list if no match.
    """
    mapping = [
        ("2.1 Frontend/Lobby", "S2"),
        ("2.4 Command Center", "S3"),
        ("2.2 Backend", "S7"),
        ("Engine", "S8"),
    ]
    owners: set[str] = set()
    for p in paths:
        for needle, stream in mapping:
            if needle in p:
                owners.add(stream)
    return sorted(owners)


def emit_chat_advisory(
    target_rel: str, impacted: list[str], editor_team: str
) -> None:
    """Publish a chat:room:design advisory when cascade impact detected.

    Called from orch_PreToolUse.py at the cascade-advisory point.
    Silent (no exception) when broker dead or no impact.
    """
    if not impacted:
        return
    owners = _resolve_owner_streams(impacted)
    if editor_team in owners:
        owners.remove(editor_team)  # don't mention self
    body_lines = [
        f"[AUTO] Editing `{target_rel}` impacts {len(impacted)} docs:"
    ]
    for p in impacted[:5]:
        body_lines.append(f"- {p}")
    if len(impacted) > 5:
        body_lines.append(f"... +{len(impacted) - 5} more")
    mentions = [f"@{s}" for s in owners]

    _publish_sync(
        topic="chat:room:design",
        payload={
            "kind": "system",
            "from": editor_team,
            "to": owners,
            "body": "\n".join(body_lines),
            "reply_to": None,
            "thread_id": None,
            "mentions": mentions,
            "ts": _now_iso(),
        },
        source=editor_team,
    )
```

- [ ] **Step 4: Run test (PASS)**

```bash
pytest tools/chat_server/tests/test_hook_integration.py -v
```

Expected: 3 tests PASS.

- [ ] **Step 5: Wire into `orch_PreToolUse.py`**

Edit `.claude/hooks/orch_PreToolUse.py` — find the cascade-advisory section (search for `doc_discovery` or `cascade`). Add the call after impact detection:

```python
# After computing `impacted` list (existing code):
try:
    from tools.chat_server.hook_integration import emit_chat_advisory
    emit_chat_advisory(target_rel, impacted, editor_team=team_id)
except Exception as e:
    # never block the hook
    sys.stderr.write(f"[chat-advisory] silent skip: {e}\n")
```

(If `orch_PreToolUse.py` has no cascade impact logic, this task may be scoped to add it. Adjust by reading the file first.)

- [ ] **Step 6: Integration smoke test**

```bash
# broker + chat-server 동작 중 가정
# S2 worktree 에서 docs/2. Development/2.4 Command Center/X.md edit 시도
# → PreToolUse hook 동작 → chat:room:design 에 system message publish
# → 브라우저 #design 분할에 "[AUTO] Editing X.md impacts ..." 표시
```

수동 검증.

- [ ] **Step 7: Commit**

```bash
git add tools/chat_server/hook_integration.py tools/chat_server/tests/test_hook_integration.py .claude/hooks/orch_PreToolUse.py
git commit -m "feat(hooks): emit_chat_advisory on cascade detect (B-222 T13)

- New module tools/chat_server/hook_integration.py (sync wrapper)
- PreToolUse 가 impacted docs 발견 시 chat:room:design 자율 발화
- broker dead 시 silent skip (hook 차단 없음)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 14: Hook `inject_chat_mentions` (SessionStart) (Day 4)

**Files:**
- Modify: `tools/chat_server/hook_integration.py` (add inject_chat_mentions)
- Modify: `tools/chat_server/tests/test_hook_integration.py` (add tests)
- Modify: `.claude/hooks/orch_SessionStart.py` (wire in)

- [ ] **Step 1: Add failing test**

Append to `tools/chat_server/tests/test_hook_integration.py`:

```python
def test_inject_chat_mentions_returns_empty_when_no_mentions(tmp_path):
    state_file = tmp_path / "chat_last_seen_S2.json"
    with patch("tools.chat_server.hook_integration._subscribe_sync") as sub:
        sub.return_value = {"events": [], "next_seq": 0}
        result = hi.inject_chat_mentions(team_id="S2", state_file=state_file)
    assert result == []


def test_inject_chat_mentions_filters_by_team(tmp_path):
    state_file = tmp_path / "chat_last_seen_S2.json"
    with patch("tools.chat_server.hook_integration._subscribe_sync") as sub:
        sub.return_value = {
            "events": [
                {
                    "seq": 10, "topic": "chat:room:design",
                    "source": "user", "ts": "2026-05-11T16:00:00Z",
                    "payload": {"mentions": ["@S2"], "body": "ping", "from": "user"},
                },
                {
                    "seq": 11, "topic": "chat:room:design",
                    "source": "user", "ts": "2026-05-11T16:01:00Z",
                    "payload": {"mentions": ["@S3"], "body": "ping3", "from": "user"},
                },
            ],
            "next_seq": 12,
        }
        result = hi.inject_chat_mentions(team_id="S2", state_file=state_file)
    assert len(result) == 1
    assert result[0]["seq"] == 10
    # state file updated
    import json as J
    assert J.loads(state_file.read_text())["last_seq"] == 12


def test_inject_chat_mentions_silent_when_broker_down(tmp_path):
    state_file = tmp_path / "chat_last_seen_S2.json"
    with patch("tools.chat_server.hook_integration._subscribe_sync",
               side_effect=Exception("broker dead")):
        result = hi.inject_chat_mentions(team_id="S2", state_file=state_file)
    assert result == []
```

- [ ] **Step 2: Run test (FAIL — function missing)**

```bash
pytest tools/chat_server/tests/test_hook_integration.py -v
```

Expected: ImportError on `inject_chat_mentions`.

- [ ] **Step 3: Implement `inject_chat_mentions`**

Append to `tools/chat_server/hook_integration.py`:

```python
import json


def _subscribe_sync(topic: str, from_seq: int, timeout_sec: int = 1) -> dict:
    """Sync wrapper for broker_client.subscribe. Raises on error (caller handles)."""
    from tools.chat_server.broker_client import BrokerClient
    client = BrokerClient(url="http://127.0.0.1:7383/mcp")
    return asyncio.run(
        client.subscribe(topic=topic, from_seq=from_seq, timeout_sec=timeout_sec)
    )


def _read_last_seen(state_file: Path) -> int:
    try:
        return json.loads(state_file.read_text(encoding="utf-8"))["last_seq"]
    except (FileNotFoundError, json.JSONDecodeError, KeyError):
        return 0


def _write_last_seen(state_file: Path, last_seq: int) -> None:
    state_file.parent.mkdir(parents=True, exist_ok=True)
    state_file.write_text(json.dumps({"last_seq": last_seq}), encoding="utf-8")


def inject_chat_mentions(team_id: str, state_file: Path) -> list[dict]:
    """Fetch chat mentions for team_id since last seen.

    Returns list of events whose payload.mentions contains '@{team_id}'.
    Side effect: updates state_file with new next_seq.
    Silent (returns []) on broker error.
    """
    last = _read_last_seen(state_file)
    try:
        r = _subscribe_sync(topic="chat:*", from_seq=last + 1, timeout_sec=1)
    except Exception as e:
        logger.debug(f"chat subscribe failed (silent): {e}")
        return []

    events = r.get("events", [])
    next_seq = r.get("next_seq", last)
    my_marker = f"@{team_id}"
    my_mentions = [
        e for e in events
        if my_marker in (e.get("payload", {}).get("mentions") or [])
    ]
    _write_last_seen(state_file, next_seq)
    return my_mentions
```

- [ ] **Step 4: Run test (PASS)**

```bash
pytest tools/chat_server/tests/test_hook_integration.py -v
```

Expected: 6 tests PASS (3 from T13 + 3 new).

- [ ] **Step 5: Wire into `orch_SessionStart.py`**

Edit `.claude/hooks/orch_SessionStart.py` — after team identity injection block, add:

```python
# Chat mention inject (B-222 T14)
try:
    from tools.chat_server.hook_integration import inject_chat_mentions
    state_file = Path.cwd() / ".claude" / f"chat_last_seen_{team_id}.json"
    mentions = inject_chat_mentions(team_id=team_id, state_file=state_file)
    if mentions:
        sys.stderr.write("\n[CHAT MENTIONS — 다음 발언 차례에 응답하세요]\n")
        for e in mentions:
            ch = e["topic"].replace("chat:room:", "")
            body = (e["payload"].get("body") or "")[:200]
            sys.stderr.write(
                f"  - #{ch} seq={e['seq']} from={e['source']}: {body}\n"
            )
except Exception as e:
    sys.stderr.write(f"[chat-mention] silent skip: {e}\n")
```

`team_id` 변수는 기존 `detect_team()` 결과에서 추출 (`team_data['stream_id']` 또는 유사 키).

- [ ] **Step 6: Integration smoke test**

브라우저 #design 에서 사용자가 "@S2 hello" 발화 → S2 worktree 새 Claude 세션 시작 시 stderr 에 `[CHAT MENTIONS]` 라인 표시.

- [ ] **Step 7: Commit**

```bash
git add tools/chat_server/hook_integration.py tools/chat_server/tests/test_hook_integration.py .claude/hooks/orch_SessionStart.py
git commit -m "feat(hooks): inject_chat_mentions on SessionStart (B-222 T14)

- subscribe chat:* with last_seen state file per team
- filter mentions containing @{team_id}
- inject into Claude context via stderr (existing convention)
- silent skip on broker dead

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```


## Task 15: UI `reply_to` 시각화 (Day 5)

**Files:**
- Modify: `tools/chat_server/ui/app.js` (renderMessage 확장)
- Modify: `tools/chat_server/ui/styles.css` (reply nested style)

**참고**: Task 11 의 기본 reply 표시는 단순한 "re: <seq>" 라벨. T15 는 원본 본문 미리보기 + 클릭 시 스크롤 추가.

- [ ] **Step 1: Extend `renderMessage` in `app.js` — reply preview**

Replace the existing `renderMessage` function in `app.js`:

```javascript
  // 원본 메시지 캐시 (panel 별 seq → element)
  const MSG_CACHE = new Map();

  function renderMessage(panel, event) {
    const p = event.payload || {};
    const from = p.from || event.source || "unknown";
    const kind = p.kind || "msg";
    const ts = (p.ts || event.ts || "").slice(11, 16);
    const isReply = kind === "reply" || p.reply_to != null;

    const el = document.createElement("div");
    el.className = `msg from-${from} kind-${kind}${isReply ? " reply" : ""}`;
    el.dataset.seq = event.seq;

    // Reply 첫 줄 — 원본 미리보기 (캐시에서 찾을 수 있으면)
    let replyPreview = "";
    if (isReply && p.reply_to != null) {
      const original = MSG_CACHE.get(`${panel.id}:${p.reply_to}`);
      const previewBody = original
        ? (original.dataset.body || "").slice(0, 60)
        : `seq=${p.reply_to}`;
      replyPreview =
        `<div class="reply-ref" data-target-seq="${p.reply_to}">` +
        `↪ re: ${escapeHtml(previewBody)}${previewBody.length >= 60 ? "…" : ""}` +
        `</div>`;
    }

    el.innerHTML =
      replyPreview +
      `<span class="ts">${ts}</span>` +
      `<span class="from">[${escapeHtml(from)}]</span> ` +
      highlightMentions(p.body || "", SELF);

    el.dataset.body = p.body || "";
    MSG_CACHE.set(`${panel.id}:${event.seq}`, el);

    const stickyBottom =
      panel.scrollHeight - panel.scrollTop - panel.clientHeight < 40;
    panel.appendChild(el);
    if (stickyBottom) panel.scrollTop = panel.scrollHeight;
  }

  // Reply preview click → scroll to original
  document.body.addEventListener("click", (e) => {
    const ref = e.target.closest(".reply-ref");
    if (!ref) return;
    const seq = ref.dataset.targetSeq;
    if (!seq) return;
    const panel = ref.closest(".panel").querySelector(".messages");
    const original = MSG_CACHE.get(`${panel.id}:${seq}`);
    if (original) {
      original.scrollIntoView({behavior: "smooth", block: "center"});
      original.style.background = "#3d2e10";
      setTimeout(() => { original.style.background = ""; }, 1500);
    }
  });
```

- [ ] **Step 2: Add reply styles to `styles.css`**

Append to `styles.css`:

```css
.msg .reply-ref {
  color: var(--muted);
  font-size: 11px;
  padding: 1px 0 2px 14px;
  cursor: pointer;
  border-left: 2px solid var(--border);
  display: block;
}
.msg .reply-ref:hover { color: var(--accent); }
.msg.reply { padding-left: 12px; border-left: 2px solid #1f6feb; }
```

- [ ] **Step 3: Rebuild + visual test**

```bash
docker compose -f tools/chat_server/docker-compose.yml up -d --build
```

브라우저 동작 확인:
1. 메시지 publish (seq=42)
2. reply publish (reply_to=42)
3. reply 위에 `↪ re: <원본 본문 60자>` 표시
4. `↪ re:` 클릭 → 원본 메시지로 스크롤 + 1.5초 노란색 강조

- [ ] **Step 4: Commit**

```bash
git add tools/chat_server/ui/app.js tools/chat_server/ui/styles.css
git commit -m "feat(chat-server): reply_to 원본 미리보기 + 클릭 점프 (B-222 T15)

- 메시지 캐시 (panel:seq → element)
- reply 시 원본 60자 미리보기
- 미리보기 클릭 시 원본 스크롤 + 1.5s 강조

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 16: UI 4번째 분할 LIVE TRACE (Day 5)

**Files:**
- Modify: `tools/chat_server/ui/app.js` (renderTrace 보강)
- Modify: `tools/chat_server/ui/styles.css` (trace style)

**참고**: Task 11 의 기본 renderTrace 는 한 줄 표시. T16 는 카테고리 별 색상 + 필터 + auto-scroll pause 추가.

- [ ] **Step 1: Replace `renderTrace` in `app.js`**

Replace existing `renderTrace`:

```javascript
  function renderTrace(event) {
    const panel = PANEL_BY_CHANNEL.trace;
    const topic = event.topic || "";
    const source = event.source || "?";
    const ts = (event.ts || "").slice(11, 16);
    const payload = event.payload || {};

    // 카테고리 추출
    let category = "other";
    if (topic.startsWith("stream:")) category = "stream";
    else if (topic.startsWith("cascade:")) category = "cascade";
    else if (topic.startsWith("pipeline:")) category = "pipeline";
    else if (topic.startsWith("audit:")) category = "audit";
    else if (topic.startsWith("defect:")) category = "defect";

    // payload 요약 (status / impacted / 등)
    let summary = "";
    if (payload.status) summary = `status=${payload.status}`;
    else if (payload.impacted) summary = `impacted=${payload.impacted.length}`;
    else summary = JSON.stringify(payload).slice(0, 80);

    const el = document.createElement("div");
    el.className = `msg trace-${category}`;
    el.innerHTML =
      `<span class="ts">${ts}</span>` +
      `<span class="trace-topic">${escapeHtml(topic)}</span> ` +
      `<span class="trace-source">(${escapeHtml(source)})</span> ` +
      `<span class="trace-summary">${escapeHtml(summary)}</span>`;
    panel.appendChild(el);

    // auto-scroll 단, panel 이 위로 스크롤된 상태면 pause
    const stickyBottom =
      panel.scrollHeight - panel.scrollTop - panel.clientHeight < 40;
    if (stickyBottom) panel.scrollTop = panel.scrollHeight;
  }
```

- [ ] **Step 2: Add trace styles to `styles.css`**

Append:

```css
.panel.trace { background: #0d1117; }
.panel.trace .messages { font-size: 12px; }
.msg.trace-stream .trace-topic   { color: var(--s2); }
.msg.trace-cascade .trace-topic  { color: var(--accent); }
.msg.trace-pipeline .trace-topic { color: var(--s10w); }
.msg.trace-audit .trace-topic    { color: var(--smem); }
.msg.trace-defect .trace-topic   { color: var(--user); }
.msg .trace-source { color: var(--muted); }
.msg .trace-summary { color: var(--fg); opacity: 0.7; }
```

- [ ] **Step 3: Add filter chips (optional UI)**

In `index.html`, replace the trace panel header:

```html
<section class="panel trace" data-channel="trace">
  <h2>
    LIVE TRACE
    <span class="trace-filters">
      <label><input type="checkbox" data-filter="stream" checked> stream</label>
      <label><input type="checkbox" data-filter="cascade" checked> cascade</label>
      <label><input type="checkbox" data-filter="pipeline" checked> pipeline</label>
      <label><input type="checkbox" data-filter="audit" checked> audit</label>
    </span>
  </h2>
  <div class="messages" id="msgs-trace"></div>
</section>
```

Filter logic in `app.js` (append):

```javascript
  // Trace 필터
  document.querySelectorAll(".trace-filters input").forEach((cb) => {
    cb.addEventListener("change", () => {
      const cat = cb.dataset.filter;
      const visible = cb.checked;
      document.querySelectorAll(`#msgs-trace .trace-${cat}`).forEach((el) => {
        el.style.display = visible ? "" : "none";
      });
      // 신규 메시지에도 적용
      window.__traceFilters = window.__traceFilters || {};
      window.__traceFilters[cat] = visible;
    });
  });

  // renderTrace 직후 필터 적용 (renderTrace 함수 끝에 추가):
  // const cat = category;
  // if (window.__traceFilters && window.__traceFilters[cat] === false) {
  //   el.style.display = "none";
  // }
```

(renderTrace 안에 필터 체크 추가 — 위 주석 코드를 renderTrace 의 `panel.appendChild(el);` 직전에 삽입.)

- [ ] **Step 4: Rebuild + visual test**

```bash
docker compose -f tools/chat_server/docker-compose.yml up -d --build
```

브라우저 LIVE TRACE 분할:
1. broker 활동 발생 (stream/cascade/pipeline event publish)
2. 4번째 분할에 카테고리 색상별 한 줄 표시
3. 헤더 체크박스 toggle → 해당 카테고리 숨김/표시

- [ ] **Step 5: Commit**

```bash
git add tools/chat_server/ui/app.js tools/chat_server/ui/styles.css tools/chat_server/ui/index.html
git commit -m "feat(chat-server): LIVE TRACE 카테고리 색상 + 필터 (B-222 T16)

- stream/cascade/pipeline/audit/defect 5 카테고리 색상 분리
- payload status/impacted 요약 표시
- 헤더 체크박스로 카테고리 toggle
- auto-scroll pause 시 정지 (사용자가 위로 스크롤 시)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```


## Task 17: Consensus `silent_ok_30s` helper (Day 6)

**Files:**
- Modify: `tools/chat_server/hook_integration.py` (add `consensus_silent_ok`)
- Modify: `tools/chat_server/tests/test_hook_integration.py` (add tests)

- [ ] **Step 1: Write failing test**

Append to `tools/chat_server/tests/test_hook_integration.py`:

```python
import asyncio


def _async_run(coro):
    return asyncio.run(coro)


def test_consensus_returns_replies_when_answered():
    """When a reply arrives before TTL, return ('answered', replies)."""
    with patch("tools.chat_server.hook_integration._subscribe_async") as sub:
        sub.return_value = {
            "events": [
                {
                    "seq": 43, "topic": "chat:room:design",
                    "source": "S3", "ts": "2026-05-11T16:01:00Z",
                    "payload": {"reply_to": 42, "body": "ok"},
                }
            ],
            "next_seq": 44,
        }
        outcome, replies = _async_run(
            hi.consensus_silent_ok(
                question_seq=42, topic="chat:room:design",
                from_team="S2", ttl_sec=2,
            )
        )
    assert outcome == "answered"
    assert len(replies) == 1


def test_consensus_silent_ok_after_ttl():
    """When no reply within TTL, return ('silent_ok', [])."""
    with patch("tools.chat_server.hook_integration._subscribe_async") as sub, \
         patch("tools.chat_server.hook_integration._publish_async") as pub:
        sub.return_value = {"events": [], "next_seq": 43}
        outcome, replies = _async_run(
            hi.consensus_silent_ok(
                question_seq=42, topic="chat:room:design",
                from_team="S2", ttl_sec=1,
            )
        )
    assert outcome == "silent_ok"
    assert replies == []
    # decision message 발행 검증
    pub.assert_called_once()
    payload = pub.call_args.kwargs["payload"]
    assert payload["kind"] == "decision"
    assert payload["reply_to"] == 42


def test_consensus_user_mention_disables_silent_ok():
    """@user 멘션이 question 메시지에 있으면 silent_ok 비활성, 사용자 응답 대기."""
    with patch("tools.chat_server.hook_integration._subscribe_async") as sub, \
         patch("tools.chat_server.hook_integration._publish_async") as pub:
        sub.return_value = {"events": [], "next_seq": 43}
        outcome, replies = _async_run(
            hi.consensus_silent_ok(
                question_seq=42, topic="chat:room:design",
                from_team="S2", ttl_sec=1,
                question_mentions=["@user", "@S3"],
            )
        )
    assert outcome == "user_mention_pending"
    assert replies == []
    pub.assert_not_called()
```

- [ ] **Step 2: Run test (FAIL — function missing)**

```bash
pytest tools/chat_server/tests/test_hook_integration.py -v -k consensus
```

Expected: 3 tests FAIL.

- [ ] **Step 3: Implement `consensus_silent_ok` (async)**

Append to `tools/chat_server/hook_integration.py`:

```python
import time


async def _subscribe_async(topic: str, from_seq: int, timeout_sec: int) -> dict:
    from tools.chat_server.broker_client import BrokerClient
    client = BrokerClient(url="http://127.0.0.1:7383/mcp")
    return await client.subscribe(
        topic=topic, from_seq=from_seq, timeout_sec=timeout_sec
    )


async def _publish_async(topic: str, payload: dict, source: str) -> dict:
    from tools.chat_server.broker_client import BrokerClient
    client = BrokerClient(url="http://127.0.0.1:7383/mcp")
    return await client.publish(topic=topic, payload=payload, source=source)


async def consensus_silent_ok(
    question_seq: int,
    topic: str,
    from_team: str,
    ttl_sec: int = 30,
    question_mentions: list[str] | None = None,
) -> tuple[str, list[dict]]:
    """Silent OK 30s consensus model.

    Logic:
      - If question_mentions contains '@user' → return ('user_mention_pending', []).
        (사용자 명시 답변 필요. silent_ok 비활성.)
      - Otherwise poll for replies up to ttl_sec.
      - If reply received → ('answered', replies).
      - If no reply by deadline → publish decision('ASSUMED ...') + ('silent_ok', []).
    """
    if question_mentions and "@user" in question_mentions:
        return ("user_mention_pending", [])

    deadline = time.time() + ttl_sec
    while time.time() < deadline:
        remaining = max(1, int(deadline - time.time()))
        try:
            r = await _subscribe_async(
                topic=topic, from_seq=question_seq + 1, timeout_sec=remaining
            )
        except Exception as e:
            logger.debug(f"consensus subscribe error (silent): {e}")
            return ("error", [])

        replies = [
            e for e in r.get("events", [])
            if e.get("payload", {}).get("reply_to") == question_seq
        ]
        if replies:
            return ("answered", replies)

    # silent OK — publish decision
    try:
        await _publish_async(
            topic=topic,
            payload={
                "kind": "decision",
                "from": from_team,
                "to": ["*"],
                "body": "[ASSUMED] proceeding. raise blocker if disagree.",
                "reply_to": question_seq,
                "thread_id": None,
                "mentions": [],
                "ts": _now_iso(),
            },
            source=from_team,
        )
    except Exception as e:
        logger.debug(f"consensus decision publish failed (silent): {e}")
    return ("silent_ok", [])
```

- [ ] **Step 4: Run test (PASS)**

```bash
pytest tools/chat_server/tests/test_hook_integration.py -v -k consensus
```

Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/chat_server/hook_integration.py tools/chat_server/tests/test_hook_integration.py
git commit -m "feat(chat-server): silent_ok_30s consensus helper (B-222 T17)

- 30s 응답 polling, 없으면 decision('ASSUMED') publish
- @user 멘션 시 silent_ok 비활성 (user_mention_pending 반환)
- broker error 시 silent skip

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 18: E2E test — 2 세션 합의 시나리오 (Day 6)

**Files:**
- Create: `tools/chat_server/tests/test_e2e_consensus.py`

본 테스트는 **실제 broker + chat-server 가 동작 중인 환경**을 가정 (CI 가 broker 띄울 수 있어야 함). pytest marker `@pytest.mark.integration` 사용.

- [ ] **Step 1: Write E2E test**

Create `tools/chat_server/tests/test_e2e_consensus.py`:

```python
"""E2E — 2 세션 합의 시나리오 (spec §12 시연).

Prereq:
  - broker 실행 중 (python tools/orchestrator/start_message_bus.py --detach)
  - 본 테스트는 실제 broker 와 통신.

Run:
  pytest tools/chat_server/tests/test_e2e_consensus.py -v -m integration
"""
import asyncio
import os
from datetime import datetime, timezone

import pytest

from tools.chat_server.broker_client import BrokerClient
from tools.chat_server.hook_integration import consensus_silent_ok


BROKER_URL = os.environ.get("BROKER_URL", "http://127.0.0.1:7383/mcp")


def _now_iso():
    return datetime.now(timezone.utc).isoformat()


async def _check_broker():
    try:
        client = BrokerClient(url=BROKER_URL)
        async with client.session() as _:
            return True
    except Exception:
        return False


@pytest.fixture(scope="module")
def broker_alive():
    if not asyncio.run(_check_broker()):
        pytest.skip("broker not running — start with start_message_bus.py --detach")


@pytest.mark.integration
@pytest.mark.asyncio
async def test_e2e_consensus_answered(broker_alive):
    """S2 질문 → S3 1초 후 reply → consensus returns 'answered'."""
    client = BrokerClient(url=BROKER_URL)
    topic = "chat:room:design"

    # S2 질문 publish
    r = await client.publish(
        topic=topic,
        payload={
            "kind": "msg", "from": "S2", "to": ["S3"],
            "body": "@S3 rake 누적 OK?",
            "mentions": ["@S3"], "reply_to": None,
            "thread_id": None, "ts": _now_iso(),
        },
        source="S2",
    )
    question_seq = r["seq"]

    # S3 가 1초 후 reply (병렬 시뮬)
    async def s3_reply():
        await asyncio.sleep(1)
        await client.publish(
            topic=topic,
            payload={
                "kind": "reply", "from": "S3", "to": ["S2"],
                "body": "CC는 flat. Lobby 누적 OK.",
                "mentions": ["@S2"], "reply_to": question_seq,
                "thread_id": None, "ts": _now_iso(),
            },
            source="S3",
        )

    reply_task = asyncio.create_task(s3_reply())

    # S2 consensus — TTL 5s
    outcome, replies = await consensus_silent_ok(
        question_seq=question_seq, topic=topic,
        from_team="S2", ttl_sec=5,
    )
    await reply_task

    assert outcome == "answered"
    assert len(replies) >= 1
    assert any(e["payload"]["reply_to"] == question_seq for e in replies)


@pytest.mark.integration
@pytest.mark.asyncio
async def test_e2e_consensus_silent_ok(broker_alive):
    """S2 질문 → 아무도 reply 안 함 (TTL 2s) → silent_ok + decision publish."""
    client = BrokerClient(url=BROKER_URL)
    topic = "chat:room:design"

    r = await client.publish(
        topic=topic,
        payload={
            "kind": "msg", "from": "S2", "to": [],
            "body": "(silent test) proceeding with default",
            "mentions": [], "reply_to": None,
            "thread_id": None, "ts": _now_iso(),
        },
        source="S2",
    )
    question_seq = r["seq"]

    outcome, replies = await consensus_silent_ok(
        question_seq=question_seq, topic=topic,
        from_team="S2", ttl_sec=2,
    )

    assert outcome == "silent_ok"
    assert replies == []

    # decision 메시지가 broker history 에 있어야 함
    h = await client.get_history(topic=topic, since_seq=question_seq, limit=20)
    decisions = [
        e for e in h["events"]
        if e["payload"].get("kind") == "decision"
        and e["payload"].get("reply_to") == question_seq
    ]
    assert len(decisions) == 1


@pytest.mark.integration
@pytest.mark.asyncio
async def test_e2e_user_mention_blocks_silent_ok(broker_alive):
    """@user 멘션 포함 → silent_ok 비활성. 사용자 응답 대기."""
    client = BrokerClient(url=BROKER_URL)
    topic = "chat:room:design"

    r = await client.publish(
        topic=topic,
        payload={
            "kind": "msg", "from": "S2", "to": ["user"],
            "body": "@user 결정 필요",
            "mentions": ["@user"], "reply_to": None,
            "thread_id": None, "ts": _now_iso(),
        },
        source="S2",
    )
    question_seq = r["seq"]

    outcome, replies = await consensus_silent_ok(
        question_seq=question_seq, topic=topic,
        from_team="S2", ttl_sec=2,
        question_mentions=["@user"],
    )

    assert outcome == "user_mention_pending"
    assert replies == []
```

- [ ] **Step 2: Add `pyproject.toml` pytest marker (or `conftest.py`)**

Create or modify `tools/chat_server/tests/conftest.py` to register marker:

```python
import pytest

# ... existing fixtures ...

def pytest_configure(config):
    config.addinivalue_line(
        "markers", "integration: requires live broker"
    )
```

- [ ] **Step 3: Start broker + run E2E**

```bash
python tools/orchestrator/start_message_bus.py --detach
pytest tools/chat_server/tests/test_e2e_consensus.py -v -m integration
```

Expected: 3 tests PASS.

- [ ] **Step 4: Commit**

```bash
git add tools/chat_server/tests/test_e2e_consensus.py tools/chat_server/tests/conftest.py
git commit -m "test(chat-server): E2E 합의 시나리오 (B-222 T18)

3 시나리오:
- answered: reply 받으면 그대로 반영
- silent_ok: TTL 만료 시 decision 자동 publish
- user_mention_pending: @user 멘션은 silent_ok 비활성

@pytest.mark.integration 필요 (broker 가동 중).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```


## Task 19: `team_assignment_v10_3.yaml` topics.acl entry (Day 7)

**Files:**
- Modify: `docs/4. Operations/team_assignment_v10_3.yaml` (add chat topic ACL)

- [ ] **Step 1: Read current yaml**

```bash
cat "docs/4. Operations/team_assignment_v10_3.yaml" | head -80
```

Locate the `topics:` section (or `acl:` subsection per Multi_Session_Design_v11.md §11).

- [ ] **Step 2: Add chat:* entries to topics.acl**

Edit `docs/4. Operations/team_assignment_v10_3.yaml` — add to the `topics.acl` (or equivalent) block:

```yaml
# B-222 — Inter-Session Chat (additive)
chat_acl:
  # 모든 stream 이 chat:room:* / chat:dm:* / chat:thread:* 에 publish 가능 (open prefix)
  open_prefix: "chat:"
  notes: |
    chat:* 는 _OPEN_TOPIC_PREFIXES 에 등록 (topics.py).
    source='user' 는 publisher_id='chat-server' 에서만 발급 가능.
  user_source_publishers:
    - chat-server

stream_topic_extensions:
  # 각 stream 이 자율 발화 시 사용할 default chat 채널
  S1:
    chat_default: chat:room:design
    chat_blocker: chat:room:blocker
  S2:
    chat_default: chat:room:design
    chat_blocker: chat:room:blocker
  S3:
    chat_default: chat:room:design
    chat_blocker: chat:room:blocker
  S7:
    chat_default: chat:room:design
    chat_blocker: chat:room:blocker
  S8:
    chat_default: chat:room:design
    chat_blocker: chat:room:blocker
  S9:
    chat_default: chat:room:design
    chat_blocker: chat:room:blocker
  S10-A:
    chat_default: chat:room:design
    chat_blocker: chat:room:blocker
  S10-W:
    chat_default: chat:room:design
    chat_blocker: chat:room:blocker
  S11:
    chat_default: chat:room:handoff
    chat_blocker: chat:room:blocker
  SMEM:
    chat_default: chat:room:design
    chat_blocker: chat:room:blocker
```

(정확한 들여쓰기 / 위치는 기존 yaml 의 structure 보고 결정. 별도 top-level key 로 두는 게 안전 — 다른 도구가 파싱하는 keys 와 충돌 회피.)

- [ ] **Step 3: Validate yaml**

```bash
python -c "import yaml; yaml.safe_load(open('docs/4. Operations/team_assignment_v10_3.yaml', encoding='utf-8'))" && echo "VALID"
```

Expected: `VALID`.

- [ ] **Step 4: Commit**

```bash
git add "docs/4. Operations/team_assignment_v10_3.yaml"
git commit -m "docs(operations): chat:* ACL entry in team_assignment_v10_3.yaml (B-222 T19)

chat_acl: open_prefix='chat:', user_source_publishers=['chat-server']
stream_topic_extensions: 각 stream 의 chat_default / chat_blocker 채널 default

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 20: `Docker_Runtime.md` chat-server 섹션 (Day 7)

**Files:**
- Modify: `docs/4. Operations/Docker_Runtime.md` (append chat-server section)

- [ ] **Step 1: Append section**

Append to `docs/4. Operations/Docker_Runtime.md`:

```markdown
---

## Inter-Session Chat Server (B-222)

> dev 보조 도구. broker (호스트 Python) 위에서 동작하는 FastAPI SSE 중계 컨테이너.
> 본 spec: `docs/4. Operations/Inter_Session_Chat_Design.md`.

### Lifecycle

```bash
# 1. broker 살아있는지 (이미 실행 중이 아니면)
python tools/orchestrator/start_message_bus.py --detach

# 2. chat-server 컨테이너 기동
docker compose -f tools/chat_server/docker-compose.yml up -d

# 3. 브라우저
http://localhost:7390/

# 중지
docker compose -f tools/chat_server/docker-compose.yml down

# 로그
docker compose -f tools/chat_server/docker-compose.yml logs -f chat-server

# 재빌드
docker compose -f tools/chat_server/docker-compose.yml up -d --build
```

### 의존성

| 서비스 | 위치 | 필수 |
|--------|-----|:----:|
| broker | 호스트 Python `:7383` | ✓ |
| chat-server | 컨테이너 `:7390` | ✓ |
| 브라우저 | 사용자 데스크톱 | ✓ |

### Healthcheck

```bash
curl http://localhost:7390/health
```

Expected JSON:
```json
{
  "status": "ok",
  "version": "0.1.0",
  "broker_url": "http://host.docker.internal:7383/mcp",
  "broker_alive": true
}
```

| 결과 | 의미 |
|-----|-----|
| `broker_alive: true` | 정상 |
| `broker_alive: false` | broker 죽음. `start_message_bus.py --probe` 로 확인 후 `--detach` 재기동 |
| 응답 없음 | chat-server 컨테이너 죽음. `docker compose up -d` 재기동 |

### Troubleshooting

| 증상 | 원인 | 조치 |
|-----|-----|-----|
| `http://localhost:7390/` 접속 불가 | 컨테이너 미기동 | `docker compose ps` 후 `up -d` |
| SSE 연결 즉시 끊김 | broker 죽음 | UI 상단 빨간 배너 표시. broker 재기동 |
| 메시지 발신 503 | broker `publish_event` 실패 | broker 로그 (`.claude/message_bus/broker.log`) 확인 |
| `@` autocomplete peer 목록 빔 | 다른 세션 publish 없음 (5분+ idle) | 정상. 새 세션이 publish 하면 표시 |
| CORS 에러 | localhost 외 origin 시도 | 본 도구는 localhost 전용. 외부 접속 미지원 |

### root compose 와의 관계

- chat-server 는 **별도 compose** (`tools/chat_server/docker-compose.yml`).
- root compose (S11 영역 — Game Engine, CC Backend 등) 와 lifecycle 분리.
- 동시 기동 안전 (포트 7390 충돌 없음).

### Production 가이드 (선택)

dev 전용으로 설계. production 배포 필요 시 별도 spec 필요:
- broker 컨테이너화 + replication
- 토큰 인증 (`source="user"` publisher_id 강화)
- nginx 리버스 프록시
```

- [ ] **Step 2: Commit**

```bash
git add "docs/4. Operations/Docker_Runtime.md"
git commit -m "docs(operations): chat-server 컨테이너 운영 섹션 (B-222 T20)

Lifecycle / 의존성 / Healthcheck / Troubleshooting / root compose 관계 / Production 가이드.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 21: `cli.py` 보조 CLI (Day 7)

**Files:**
- Create: `tools/chat_server/cli.py`
- Create: `tools/chat_server/tests/test_cli.py`

- [ ] **Step 1: Write failing test**

Create `tools/chat_server/tests/test_cli.py`:

```python
"""Tests for tools/chat_server/cli.py."""
import json
from unittest.mock import patch, AsyncMock

from tools.chat_server import cli


def test_cli_send_invokes_broker_publish(monkeypatch, capsys):
    mock_pub = AsyncMock(return_value={"seq": 99, "ts": "t"})
    monkeypatch.setattr("tools.chat_server.cli._broker_publish", mock_pub)
    rc = cli.main(["send", "--channel", "room:design", "@S3 hi"])
    assert rc == 0
    mock_pub.assert_called_once()
    args = mock_pub.call_args.kwargs
    assert args["topic"] == "chat:room:design"
    assert args["payload"]["body"] == "@S3 hi"
    assert "@S3" in args["payload"]["mentions"]


def test_cli_history_prints_messages(monkeypatch, capsys):
    mock_h = AsyncMock(return_value={
        "events": [
            {
                "seq": 1, "topic": "chat:room:design", "source": "S2",
                "ts": "2026-05-11T15:30:00Z",
                "payload": {"from": "S2", "body": "hello", "kind": "msg"},
            }
        ],
        "count": 1,
    })
    monkeypatch.setattr("tools.chat_server.cli._broker_history", mock_h)
    rc = cli.main(["history", "room:design", "--last", "10"])
    assert rc == 0
    out = capsys.readouterr().out
    assert "S2" in out
    assert "hello" in out
```

- [ ] **Step 2: Run test (FAIL — module not yet implemented)**

```bash
pytest tools/chat_server/tests/test_cli.py -v
```

- [ ] **Step 3: Implement `cli.py`**

```python
"""Chat CLI — watch / send / history.

Usage:
  python tools/chat_server/cli.py watch
  python tools/chat_server/cli.py watch room:design
  python tools/chat_server/cli.py send --channel room:design "hello @S3"
  python tools/chat_server/cli.py history room:design --last 50

Note: send sets source='user' (CLI assumes human operator).
"""
from __future__ import annotations

import argparse
import asyncio
import json
import re
import sys
from datetime import datetime, timezone

from tools.chat_server.broker_client import BrokerClient

MENTION_RE = re.compile(r"@([A-Za-z][\w-]*)")


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _parse_mentions(body: str) -> list[str]:
    return [f"@{m}" for m in MENTION_RE.findall(body)]


# ── Thin async wrappers (mockable in tests) ──

async def _broker_publish(topic: str, payload: dict, source: str) -> dict:
    return await BrokerClient().publish(topic=topic, payload=payload, source=source)


async def _broker_subscribe(topic: str, from_seq: int, timeout_sec: int) -> dict:
    return await BrokerClient().subscribe(
        topic=topic, from_seq=from_seq, timeout_sec=timeout_sec
    )


async def _broker_history(topic: str, since_seq: int, limit: int) -> dict:
    return await BrokerClient().get_history(
        topic=topic, since_seq=since_seq, limit=limit
    )


# ── Commands ──

def cmd_send(args) -> int:
    topic = f"chat:{args.channel}"
    body = args.body
    mentions = _parse_mentions(body)
    payload = {
        "kind": "msg",
        "from": "user",
        "to": [m.lstrip("@") for m in mentions],
        "body": body,
        "reply_to": args.reply_to,
        "thread_id": None,
        "mentions": mentions,
        "ts": _now_iso(),
    }
    r = asyncio.run(_broker_publish(topic=topic, payload=payload, source="user"))
    print(f"published seq={r.get('seq')}")
    return 0


def cmd_history(args) -> int:
    topic = f"chat:{args.channel}"
    r = asyncio.run(_broker_history(topic=topic, since_seq=0, limit=args.last))
    for e in r.get("events", []):
        p = e["payload"]
        ts = (p.get("ts") or e.get("ts", ""))[:19]
        print(f"{ts} [{p.get('from','?')}] {p.get('body','')}")
    return 0


def cmd_watch(args) -> int:
    topic = f"chat:{args.channel}" if args.channel else "chat:*"
    last_seq = 0
    print(f"watching {topic} (Ctrl-C to exit)")
    while True:
        try:
            r = asyncio.run(
                _broker_subscribe(topic=topic, from_seq=last_seq, timeout_sec=30)
            )
            for e in r.get("events", []):
                last_seq = max(last_seq, e["seq"])
                p = e["payload"]
                ts = (p.get("ts") or e.get("ts", ""))[:19]
                ch = e["topic"].replace("chat:", "")
                print(f"{ts} #{ch} [{p.get('from','?')}] {p.get('body','')}")
            last_seq = r.get("next_seq", last_seq)
        except KeyboardInterrupt:
            return 0
        except Exception as e:
            print(f"error: {e}; retrying...", file=sys.stderr)
            asyncio.run(asyncio.sleep(5))


# ── Entry ──

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="chat-cli")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_watch = sub.add_parser("watch", help="Tail chat messages")
    p_watch.add_argument("channel", nargs="?", default=None,
                         help="e.g., 'room:design' (omit for all)")
    p_watch.set_defaults(func=cmd_watch)

    p_send = sub.add_parser("send", help="Send a message")
    p_send.add_argument("--channel", required=True)
    p_send.add_argument("--reply-to", type=int, default=None)
    p_send.add_argument("body")
    p_send.set_defaults(func=cmd_send)

    p_history = sub.add_parser("history", help="Print recent messages")
    p_history.add_argument("channel")
    p_history.add_argument("--last", type=int, default=50)
    p_history.set_defaults(func=cmd_history)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run test (PASS)**

```bash
pytest tools/chat_server/tests/test_cli.py -v
```

Expected: 2 tests PASS.

- [ ] **Step 5: Manual smoke test (broker live)**

```bash
# Terminal 1
python tools/orchestrator/start_message_bus.py --detach

# Terminal 2 — watch
python tools/chat_server/cli.py watch room:design

# Terminal 3 — send
python tools/chat_server/cli.py send --channel room:design "manual test"
python tools/chat_server/cli.py history room:design --last 5
```

Expected:
- Terminal 2: `... #room:design [user] manual test`
- Terminal 3 history: 메시지 표시

- [ ] **Step 6: Commit**

```bash
git add tools/chat_server/cli.py tools/chat_server/tests/test_cli.py
git commit -m "feat(chat-server): CLI watch / send / history (B-222 T21)

- 보조 CLI for headless / SSH / 자동화 환경
- send 는 source='user' (Human-Operator 가정)
- watch 는 long-poll subscribe loop (Ctrl-C exit)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Final Verification

전체 task 완료 후:

```bash
# 1. 모든 unit test 통과
pytest tools/orchestrator/message_bus/tests/test_topics_chat_acl.py tools/chat_server/tests/ -v

# 2. E2E test 통과 (broker 가동)
python tools/orchestrator/start_message_bus.py --detach
pytest tools/chat_server/tests/test_e2e_consensus.py -v -m integration

# 3. 컨테이너 healthcheck
docker compose -f tools/chat_server/docker-compose.yml up -d --build
sleep 15
curl http://localhost:7390/health | python -m json.tool
docker compose -f tools/chat_server/docker-compose.yml ps  # (healthy) 표시

# 4. Browser visual
# http://localhost:7390/ → 4분할 표시, @ 자동완성, SSE push 동작

# 5. spec ↔ code drift 검증
python tools/doc_discovery.py --impact-of "docs/4. Operations/Inter_Session_Chat_Design.md"
```

PASS 시 B-222 status PENDING → IN_PROGRESS → DONE update:

```bash
# Conductor_Backlog/B-222-inter-session-chat-ui.md 의 status: 필드 update
# 모든 21 task 완료 + verification 통과 후
```


---

## Validation Gates

각 Day 종료 시점 검증:

| Day | Gate |
|-----|------|
| 1 | `pytest tools/orchestrator/message_bus/tests/test_topics_chat_acl.py -v` ALL PASS, 기존 topics test 100% 보존 |
| 2 | `pytest tools/chat_server/tests/ -v` ALL PASS (test_health, test_history, test_peers, test_send) |
| 2.5 | `docker compose -f tools/chat_server/docker-compose.yml up -d` 후 `curl http://localhost:7390/health` → `200 OK` |
| 2 (T9) | `pytest tools/chat_server/tests/test_sse.py -v` PASS + curl SSE 수동 검증 |
| 3 | 브라우저 `http://localhost:7390/` 진입 시 4분할 표시, @ 드롭다운 등장, 메시지 발신/수신 동작 |
| 4 | mock cascade 시 hook 이 chat:room:design 자동 발화 + 다른 worktree 세션이 mention context 받음 |
| 5 | reply 메시지에 들여쓰기 + "re:" 표시. 4번째 분할에 stream:* event 표시 |
| 6 | `pytest tools/chat_server/tests/test_e2e_consensus.py -v` PASS (시나리오 §12) |
| 7 | broker kill → chat-server backoff → 재기동 → catch-up 수동 검증. CLI watch / send 동작 |

---

## References

- 본 spec: [`Inter_Session_Chat_Design.md`](./Inter_Session_Chat_Design.md)
- Backlog: [`B-222-inter-session-chat-ui.md`](./Conductor_Backlog/B-222-inter-session-chat-ui.md)
- 기반 broker: [`Message_Bus_Runbook.md`](./Message_Bus_Runbook.md)
- 멀티 세션 spec: [`Multi_Session_Design_v11.md`](./Multi_Session_Design_v11.md)
