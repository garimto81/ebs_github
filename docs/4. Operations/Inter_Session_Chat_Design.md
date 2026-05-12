---
title: Inter-Session Chat — Design Specification
owner: conductor
tier: internal
status: DESIGN
plan: TBD (writing-plans skill 다음 단계)
last-updated: 2026-05-11
related-backlog: docs/4. Operations/Conductor_Backlog/B-222-inter-session-chat-ui.md
predecessors:
  - path: docs/4. Operations/Message_Bus_Runbook.md
    relation: foundation
    reason: chat layer 가 기존 message_bus broker 위에 어댑터 형태로 얹힘
  - path: docs/4. Operations/Multi_Session_Design_v11.md
    relation: extends
    reason: v11 의 7중 다층 방어 (Topic ACL) 위에 chat:* prefix 추가
confluence-page-id: TBD
confluence-parent-id: 3811573898
---

# Inter-Session Chat — Design Specification

> **Thesis**: 기존 message_bus broker 위에 **채팅 어휘** 를 얹는다. 인프라는 그대로, 의미론만 추가. event = "일이 일어났다" / chat = "내가 너에게 말한다". 두 모델은 상보적.

## Reader Anchor

이 문서는 멀티 세션 협업 인프라의 **대화 레이어 신설** SSOT. 입구 (현재 v11 event-only) → 출구 (chat:* topic + Web UI 4분할 + Docker 컨테이너 + 세션 자율 발화 정책).

본 문서가 다루는 것:
- chat-payload schema (자유 텍스트 + 멘션 + 스레드)
- chat:{room} topic 컨벤션 + ACL 완화
- FastAPI chat-server 아키텍처 (Docker 컨테이너)
- Web UI 4분할 mockup + @ 인터랙션 흐름
- 세션 자율 발화 트리거 (hook 통합)
- 합의 모델 (silent OK 30s) + escalation
- broker SPOF 시 graceful degradation

본 문서가 다루지 않는 것:
- 기존 event bus 의 8 stream pub/sub (Message_Bus_Runbook 그대로)
- Authentication / authorization (localhost dev 전제)
- production 배포 (dev 보조 도구로 한정)

---

## §1. 현재 갭 (Why)

기존 broker (`http://127.0.0.1:7383/mcp`) 는 **이벤트 알림판** 으로 설계됨:

```
   세션 S2 -----publish_event(topic="stream:S2",         broker
                payload={"status":"DONE","pr":195})  ---> events.db
                                                            |
   세션 S3 ----subscribe(topic="stream:S2", from_seq=0) <--+  (push 50ms)
                받은 것: {"seq":42, "topic":"stream:S2",
                          "payload":{"status":"DONE"}, "source":"S2"}
```

7개 MCP 도구 (`publish_event`, `subscribe`, `broadcast`, `discover_peers`, `get_history`, `acquire_lock`, `release_lock`). SQLite WAL 저장. Topic ACL strict (S2 는 `stream:S2` 와 `cascade:*` 만 publish 가능).

### 6 가지 본질적 차이

| 측면 | 현재 (event bus) | 원하는 것 (chat) |
|------|-----------------|----------------|
| 페이로드 | `{"status":"DONE"}` 정형 JSON | 자유 텍스트 + (optional) metadata |
| 발화권 | ACL — 내 topic 만 publish | open — 누구나 채널에 발언 |
| 수신자 | topic subscriber (익명 다수) | 채널 멤버 + **@-mention** |
| 응답 | fire-and-forget | reply / thread (대화 사슬) |
| 사람 위치 | 외부 observer | **first-class 참여자** (Web UI) |
| 의도 | 기계 트리거 (의존성 unblock) | 의사소통 (의문 해소 / 합의) |

**핵심**: 현재는 "S2 의 라이프사이클 알림" 이고, 원하는 건 "S2 와 S3 의 대화". 전자는 *상태* 가 본질, 후자는 *대화 주체와 흐름* 이 본질.

## §2. 채팅 채널 구조

### 2.1 v1 default 채널 (3개)

```
chat:room:design     <-- PRD 정합성 / 스펙 의문 / 정본 협의
chat:room:blocker    <-- "X 가 필요한데 누가 줄 수 있어?"
chat:room:handoff    <-- stream 간 작업 인계 ("S10-W 받아주세요")
```

사용자 (`source="user"`) 는 **어느 채널에든** 발화 가능. 별도 사용자 전용 채널 없음. UI 에서 사용자 메시지는 빨간색 + 굵게로 구분 (§5.2).

### 2.2 추가 채널 패턴 (필요 시 v2+)

| 패턴 | 용도 | 예 |
|------|-----|-----|
| `chat:room:<name>` | 공용 채널 (any stream publish) | `chat:room:debug`, `chat:room:retro` |
| `chat:dm:<A>-<B>` | 1:1 (양쪽 정렬, 알파벳순) | `chat:dm:S2-S3` |
| `chat:thread:<id>` | 스레드 분기 (긴 토론 격리) | `chat:thread:rake-01` |

### 2.3 UI 4분할 배치

```
| #design    | #blocker     |
| #handoff   | LIVE TRACE   |   ← chat 아님, event bus mirror (read-only)
```

4번째 분할 = **LIVE TRACE** (event bus mirror). chat 3개 + 현장 모니터 1개. 사용자가 추후 채널 swap 옵션 추가 가능 (v2).

**비유**: 3개의 회의실 + 1개의 현장 모니터. 사용자는 어느 회의실에든 끼어들 수 있음.



## §3. Chat Payload Schema

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
| `kind` | enum | ✓ | `msg` (일반 발언) / `reply` (답장) / `system` (자동 발화) / `decision` (합의 종결) |
| `from` | string | ✓ | 발화자 stream id (`S1`~`S11`, `SMEM`, `user`) |
| `to` | string[] | | 수신자 stream id 배열. `"*"` 또는 빈 배열 = 채널 전체 |
| `body` | string | ✓ | 자유 텍스트 (markdown 허용, 최대 4000자) |
| `reply_to` | int / null | | 다른 메시지의 broker `seq` (스레드) |
| `thread_id` | string / null | | 같은 thread 그룹 식별자 (선택, reply_to 와 독립) |
| `mentions` | string[] | | `@`-prefix parse 결과 (`["@S3", "@user"]`) |
| `ts` | ISO8601 | ✓ | 발화 시각 (클라이언트 측 생성, broker `ts` 와 별개) |

**참고**: broker 가 추가하는 외부 메타 (`seq`, `topic`, `source`, broker `ts`) 는 페이로드에 중복 저장 안 함.

### 3.1 메시지 종류별 의미

| kind | 트리거 | 예 |
|------|-------|----|
| `msg` | 세션이 자발적 발언 | "@S3 rake 표기 어떻게?" |
| `reply` | `reply_to` 가 가리키는 메시지에 대한 답 | "CC 는 flat" (reply_to: 42) |
| `system` | hook 이 자동 발화 (cascade / blocker / handoff 감지) | "[AUTO] cascade detected: Foundation.md → 3 docs" |
| `decision` | thread 종결 + 합의 결과 명시 | "[DECISION] rake 누적으로 진행 (S2, S3 합의)" |

## §4. Topic ACL 완화 (단 한 줄 변경)

```python
# tools/orchestrator/message_bus/topics.py — 변경 전
_OPEN_TOPIC_PREFIXES = ("cascade:", "defect:", "audit:", "pipeline:")

# 변경 후
_OPEN_TOPIC_PREFIXES = ("cascade:", "defect:", "audit:", "pipeline:", "chat:")
#                                                                     ^^^^^^^
```

**의미**: `chat:` prefix 시작 topic 은 모든 stream 이 publish 가능. 다른 stream 의 topic 침범이 아니라, **공용 채팅 공간** 에 발화하는 것이라 정체성 침해 0.

### 4.1 사용자 source 보호 (anti-spoofing)

채널 자체에는 ACL 없지만, **`source="user"` 사용은 chat-server (Web UI) 만 가능**. 세션이 사용자를 사칭하지 못하게 차단.

```python
# topics.py 에 추가될 검증
_RESERVED_USER_SOURCE = "user"
_ALLOWED_USER_PUBLISHERS = {"chat-server"}  # chat-server 가 자신을 publisher_id 로 식별

def check_publish_acl(topic: str, source: str, publisher_id: str = "") -> tuple[bool, str]:
    # ... 기존 로직 ...
    if source == _RESERVED_USER_SOURCE and publisher_id not in _ALLOWED_USER_PUBLISHERS:
        return False, f"source='user' is reserved for Web UI (publisher_id='{publisher_id}' rejected)"
    return True, ""
```

**메커니즘**: chat-server 는 broker MCP 연결 시 `publisher_id="chat-server"` 자체 식별. 세션 hook 은 publisher_id 없음 → `source="user"` publish 시도 자동 거부.

**Production 강화 시**: 토큰 기반 인증. 본 spec 범위 밖.

### 4.2 `source` 인증 (간단)

dev 전제 (localhost) — 강한 인증 없음. chat-server (FastAPI) 가 sender header 를 그대로 broker 에 전달. 세션 발화는 `.team` 파일 기반 stream id 자동 inject. 사용자 발화는 chat-server 가 `source="user"` 하드코딩.

**Production 강화 시**: chat-server 에 stream-id 발급 토큰 + broker 측 검증 (별도 spec, 본 범위 밖).



## §5. 4분할 Web UI Mockup

```
+──────────────────────────────────────────────────────────────────────+
| EBS Chat ─ live broker 7383              S2 S3 S7 S8 S10-A S11 user  |
+─────────────────────────────────┬────────────────────────────────────+
| #design              [Live]    | #blocker             [Live]         |
| ──────────────────────────────  | ──────────────────────────────────  |
| 15:30 [S2] @S3 rake 누적 OK?   | 15:25 [S7] DB schema 대기중         |
|         Lobby 정합           | 15:28 [S8] @S7 5분 후 풀려 (PR#194) |
| 15:32 [S3] CC는 flat, 우리는    | 15:30 [S7] (typing...)              |
|         hand-by-hand 정산        |                                     |
| 15:33 [user] 누적이 맞음        |                                     |
|                                  |                                     |
| ──────────────────────────────  | ──────────────────────────────────  |
| > [@] _                          | > [@] _                              |
+─────────────────────────────────┼────────────────────────────────────+
| #handoff             [Live]    | LIVE TRACE (event bus)   [auto]     |
| ──────────────────────────────  | ──────────────────────────────────  |
| 15:20 [S10-A] gap-04 → S10-W   | 15:33 stream:S2  DONE  pr=#195      |
| 15:21 [S10-W] received          | 15:33 cascade:Foundation.md (S1)    |
| 15:29 [S10-W] @S2 PRD patched   |        impacted: 3 docs              |
|                                  | 15:34 pipeline:qa-pass (S9)         |
| ──────────────────────────────  | 15:35 audit:memory-rotate (SMEM)    |
| > [@] _                          | (subscribe="*", read-only)          |
+─────────────────────────────────┴────────────────────────────────────+
```

### 5.1 UI 핵심 동작

| 동작 | 처리 |
|------|------|
| 페이지 로딩 | 4 채널 각각 `GET /chat/history?channel=X&limit=50` → 채팅 복원 |
| 새 메시지 push | SSE 이벤트 → DOM append + auto-scroll (스크롤 위로 올린 상태면 "↓ N new" 배지) |
| `@` 입력 | 드롭다운 + `discover_peers` 결과 + 화살표 + Enter / 클릭 / Esc |
| Enter 발신 | POST `/chat/send`. Shift+Enter = 줄바꿈 |
| 멘션 하이라이트 | `@S3` 노란 배경. 본인 멘션 (`@user`) 빨간 배경 + 알림음 (선택) |
| reply_to 표시 | 답장에 작은 회색 "re: ..." 첫 줄 + 클릭 시 원본 스크롤 |
| Active 세션 헤더 | 상단 우측 chip 표시. 5분 idle 시 회색화 |

### 5.2 색상 컨벤션 (Stream identity)

```
S1 Foundation   ▌ purple        S9 QA             ▌ pink
S2 Lobby        ▌ green         S10-A             ▌ orange
S3 CC           ▌ blue          S10-W             ▌ orange-dark
S7 Backend      ▌ amber         S11 Dev Assist    ▌ slate
S8 Engine       ▌ teal          SMEM Memory       ▌ gray
                                user              ▌ red (굵게)
                                system            ▌ gray italic
```

### 5.3 4번째 분할 = LIVE TRACE (event bus mirror)

채팅 3개 (#design, #blocker, #handoff) + 현장 모니터 1개 = "회의 + 현장" 동시 관전. LIVE TRACE 는 `subscribe(topic="*")` 결과 중 `chat:*` 제외한 모든 event 를 시계열 표시. read-only.



## §6. @ 인터랙션 시퀀스

```
사용자가 #design 입력창에 "@" 키 입력
       │
       ▼
드롭다운 등장 (active sessions, last 5min 기준):
   ┌────────────────────────────────────┐
   │ @S2  (active, last 15:30)         │
   │ @S3  (active, last 15:32)  ←hover │
   │ @S7  (active, last 15:25)         │
   │ @S8  (active, last 15:28)         │
   │ @S10-A (idle, last 15:10)          │
   │ ──────                            │
   │ @user  (자가 메모용)               │
   │ @all  (채널 전체)                  │
   └────────────────────────────────────┘
       │
       ▼ 화살표 ↓ + Enter (또는 클릭)
"@S3 " 자동 삽입 + 커서 뒤로
       │
       ▼ 사용자가 메시지 타이핑 + Enter
POST /chat/send {
   channel: "room:design",
   body: "@S3 flat 표시는 CC 한정인지 확인",
   from: "user",
   mentions: ["S3"]
}
       │
       ▼
broker.publish_event(
   topic="chat:room:design",
   payload={kind:"msg", from:"user", to:["S3"], body:"...", mentions:["@S3"], ts:"..."},
   source="user"
)
       │
       ▼ 50ms push
모든 분할의 #design 채팅창에 메시지 등장 (자기 화면 포함, 일관성)
       │
       ▼ S3 의 SessionStart/PreToolUse hook 이 다음 cycle 에 mention 감지
       │
       ▼ S3 자율 reply
broker.publish_event(
   topic="chat:room:design",
   payload={kind:"reply", from:"S3", to:["user"], body:"...", reply_to:<original_seq>, mentions:["@user"], ts:"..."},
   source="S3"
)
       │
       ▼
사용자 화면에 S3 답변 등장 (reply_to 표시 — 들여쓰기 + "re: ..." 첫 줄)
```

### 6.1 Active 세션 목록 갱신

| 트리거 | 처리 |
|-------|------|
| 페이지 로딩 | `GET /chat/peers` → 드롭다운 초기화 |
| 5초 간격 | 자동 `GET /chat/peers` polling → chip 표시 업데이트 |
| 새 메시지 SSE | 발화자 source 를 active 집합에 즉시 추가 |

**Active 정의**: 최근 5분 이내 broker 에 publish 한 적 있는 source. `discover_peers()` 의 `last_seen` 사용.

### 6.2 멘션 routing (어떻게 S3 에게 도달하나?)

세션은 broker 와 별도 통신 채널이 없음. 멘션은 **payload metadata** 일 뿐. 실제 도달 메커니즘:

```
1. user 가 @S3 멘션 → broker 에 publish (mentions=["@S3"])
2. S3 세션의 hook (SessionStart / PreToolUse) 가 매 cycle 에
   subscribe(topic="chat:*", from_seq=<last_seen>, timeout_sec=1) 호출
3. 받은 메시지 중 mentions 에 "@S3" 포함된 것 필터
4. CLAUDE.md context 에 inject:
   "[CHAT MENTION] user @ #design (seq=42): '...' — 다음 발언 차례에 응답하세요"
5. Claude 가 자율 응답 → chat-server 가 아닌 broker 에 직접 publish
```



## §7. 아키텍처 + Docker 토폴로지

```
                  사용자 브라우저
                       │ http://localhost:7390/
                       │ (SSE stream + POST send)
                       ▼
        +─────────────────────────────────+
        | chat-server 컨테이너            |
        |   uvicorn :7390                 |
        |   - GET  /            (static)  |
        |   - GET  /chat/stream (SSE)    |
        |   - POST /chat/send             |
        |   - GET  /chat/peers            |
        |   - GET  /chat/history          |
        |   - GET  /health                |
        +────────────┬────────────────────+
                     │ MCP StreamableHTTP
                     │ http://host.docker.internal:7383/mcp
                     ▼
        +─────────────────────────────────+
        | broker (호스트 Python)          |
        |   tools/orchestrator/...        |
        |   :7383 (변경 없음)             |
        +─────────────────────────────────+
                     ▲
                     │ MCP (in-process, hook 호출)
                     │
        +─────────────────────────────────+
        | 8 worktree 세션 (호스트)        |
        | S1, S2, ..., S11, SMEM           |
        | hooks: SessionStart, PreToolUse  |
        +─────────────────────────────────+
```

### 7.1 책임 분리

| 컴포넌트 | 책임 | 위치 |
|---------|-----|------|
| broker | event/chat 영구 저장, push dispatch, ACL | 호스트 Python (변경 없음) |
| chat-server | broker ↔ 브라우저 SSE 중계, peer 캐시, static 서빙 | Docker 컨테이너 |
| 브라우저 | UI 렌더링, @ 인터랙션, 사용자 발화 | 사용자 데스크톱 |
| 세션 hook | mention 감지, 자율 발화 트리거 | 각 worktree (호스트 Python) |

### 7.2 폴더 구조 (신규 추가만)

```
tools/
└── chat_server/
    ├── Dockerfile
    ├── docker-compose.yml
    ├── server.py              # FastAPI (SSE + send + peers + history)
    ├── requirements.txt
    ├── ui/
    │   ├── index.html         # 4분할 정적 HTML
    │   └── app.js             # SSE 구독 + @ autocomplete
    └── cli.py                 # 보조 CLI (chat tail / send)
```

기존 `tools/orchestrator/message_bus/` 와 **완전 분리**. broker 코드는 `topics.py` 1줄만 변경.

## §8. Dockerfile + docker-compose.yml

### 8.1 Dockerfile

```dockerfile
FROM python:3.11-slim
WORKDIR /app

# 의존성
COPY tools/chat_server/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 앱 코드 + static UI
COPY tools/chat_server/server.py /app/
COPY tools/chat_server/ui /app/ui

ENV BROKER_URL=http://host.docker.internal:7383/mcp
ENV LOG_LEVEL=INFO

EXPOSE 7390
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:7390/health', timeout=2)" || exit 1

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "7390"]
```

### 8.2 requirements.txt

```
fastapi==0.115.*
uvicorn[standard]==0.32.*
sse-starlette==2.1.*
mcp==1.1.*
httpx==0.27.*
```

### 8.3 docker-compose.yml

```yaml
services:
  chat-server:
    build:
      context: ../..
      dockerfile: tools/chat_server/Dockerfile
    container_name: ebs-chat-server
    ports:
      - "7390:7390"
    environment:
      - BROKER_URL=http://host.docker.internal:7383/mcp
      - LOG_LEVEL=INFO
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:7390/health', timeout=2)"]
      interval: 30s
      timeout: 3s
      retries: 3
```

### 8.4 진입 명령

```bash
# 1. broker 살아있는지 확인 (이미 살아있으면 skip)
python tools/orchestrator/start_message_bus.py --detach

# 2. chat-server 컨테이너 기동
docker compose -f tools/chat_server/docker-compose.yml up -d

# 3. 브라우저
http://localhost:7390/

# 종료
docker compose -f tools/chat_server/docker-compose.yml down
```

### 8.5 root compose 통합 안 함 (자율 결정)

| 기준 | 자체 compose | root compose (S11) |
|------|:-----------:|:-----------------:|
| 생명주기 | dev 전용 | production |
| S11 scope 침범 | 없음 | 있음 |
| 독립 기동 | 가능 | broker 없으면 fail |
| 추후 통합 | 가능 | 이미 통합 |

→ `tools/chat_server/docker-compose.yml` 자체 보유. 추후 S11 협의 후 root compose merge 가능.



## §9. 세션 자율 발화 트리거

세션이 **언제** 채팅을 시작해야 하는지 가이드. `orch_PreToolUse.py` + `orch_SessionStart.py` hook 에 룰 임베드.

### 9.1 자동 발화 룰

| 상황 | 감지 | 자동 발화 |
|------|-----|----------|
| spec gap 감지 | `spec_drift_check.py` fail | `chat:room:design` + @{owner-stream} |
| PRD 충돌 의심 | `doc_discovery.py --impact-of` 결과에 다른 stream 의 정본 포함 | `chat:room:design` 비교 표 publish |
| 블로커 발견 (외부 의존) | `team_session_start.py` 의 dependency 미해소 | `chat:room:blocker` + @{책임 stream} |
| 작업 인계 필요 | scope 위반 시도 (PreToolUse 감지) | `chat:room:handoff` + @{owner-stream} |
| 사용자 결정 필요 | conflict resolution 실패 | 어느 채널이든 + `@user` 멘션 |
| 단순 status (DONE/BLOCKED) | `team_session_end.py` | **chat 사용 X** — 기존 `stream:S{N}` event 그대로 |

**원칙**: event = 기계 react / chat = 사람·세션 *생각*이 필요한 신호. 둘은 **상보적**, 대체 X.

### 9.2 자동 발화 의사코드 (cascade 감지)

```python
# .claude/hooks/orch_PreToolUse.py 추가 부분
def emit_chat_advisory(target_rel, impacted, editor_team):
    """cascade 감지 시 chat:room:design 에 자율 발화."""
    if len(impacted) == 0:
        return  # 영향 없음 → chat 불필요

    body = (
        f"[AUTO] Editing `{target_rel}` impacts {len(impacted)} docs:\n"
        + "\n".join(f"- {p}" for p in impacted[:5])
        + (f"\n... +{len(impacted)-5} more" if len(impacted) > 5 else "")
    )
    mentions = _resolve_owner_streams(impacted)  # ['S2', 'S3']

    _publish_sync(
        topic="chat:room:design",
        payload={
            "kind": "system",
            "from": editor_team,
            "to": mentions,
            "body": body,
            "mentions": [f"@{s}" for s in mentions],
            "ts": _now_iso(),
        },
        source=editor_team,
    )
```

### 9.3 멘션 수신 시 응답 의무

```python
# .claude/hooks/orch_SessionStart.py 추가 부분
def inject_chat_mentions(team_id, context):
    """chat:* 에서 @{team_id} 멘션된 메시지를 CLAUDE.md context 에 inject."""
    last_seq = _read_last_seen(team_id)
    r = _subscribe_sync(topic="chat:*", from_seq=last_seq, timeout_sec=1)
    my_mentions = [
        e for e in r["events"]
        if f"@{team_id}" in e["payload"].get("mentions", [])
    ]
    if not my_mentions:
        return
    context.append("[CHAT MENTIONS] 다음 발언 차례에 응답하세요:")
    for e in my_mentions:
        context.append(
            f"  - #{e['topic'].replace('chat:room:', '')} seq={e['seq']} "
            f"from={e['source']}: {e['payload']['body'][:200]}"
        )
    _write_last_seen(team_id, r["next_seq"])
```

### 9.4 발화 rate limit (폭주 방지)

| 룰 | 값 |
|----|-----|
| 세션당 분당 chat publish | 최대 10건 (자동 + 자발 합산) |
| 초과 시 | hook 이 자동 발화 skip + warning log |
| 사용자 발화 | rate limit 없음 (Web UI 직접) |

## §10. 합의 모델 — silent OK 30s

### 10.1 기본 합의 흐름

```
S2: "@S3 rake 누적으로 가도 돼?" (chat:room:design, seq=42)
       │
       ▼ 30초 대기 (S2 hook cycle 내 timer)
       │
   [응답 있음?]
   ├─ Yes (S3 reply) → S2 가 그 답 따름
   └─ No → "[ASSUMED] rake 누적 진행. 이의 있으면 stop." (system message, reply_to=42)
       │
       ▼
S2 가 작업 진행 (자율)
```

### 10.2 silent OK 30초 의사코드

```python
async def consensus_with_silent_ok(question_seq, from_team, ttl_sec=30):
    """질문 발화 후 silent OK 룰 적용."""
    deadline = time.time() + ttl_sec
    while time.time() < deadline:
        r = await subscribe(topic="chat:*", from_seq=question_seq + 1, timeout_sec=5)
        replies = [e for e in r["events"]
                   if e["payload"].get("reply_to") == question_seq]
        if replies:
            return ("answered", replies)
    # silent OK
    await publish_event(
        topic=last_topic,
        payload={
            "kind": "decision",
            "from": from_team,
            "to": ["*"],
            "body": "[ASSUMED] proceeding. raise blocker if disagree.",
            "reply_to": question_seq,
            "mentions": [],
            "ts": _now_iso(),
        },
        source=from_team,
    )
    return ("silent_ok", [])
```

### 10.3 충돌 escalation

```
S2: "rake 누적으로 진행" (decision, reply_to=42)
       │
       ▼ (S3 가 늦게 cycle 진입)
S3: "@S2 잠깐, 우리는 flat 으로 표시해" (msg, reply_to=42)
       │
       ▼ S2 hook 이 자기 decision 이후 반대 의견 감지
       │
       ▼ 자동 escalation
chat:room:blocker 로 thread 이전 + @user 멘션:
   "[BLOCKED] S2 decision (seq=43) contradicts S3 reply (seq=51).
    @user 결정 필요. thread_id=rake-01"
       │
       ▼ 사용자가 Web UI 로 #blocker 에서 명시적 발언
user: "@S2 @S3 누적이 맞음. flat 은 CC 표시용으로만." (msg, mentions=[@S2, @S3])
       │
       ▼ S2/S3 hook 이 user mention 감지 → 다음 cycle 에 작업 방향 조정
```

### 10.4 합의 모델 변형 (필요 시 v2)

| 변형 | 적용 시점 |
|------|----------|
| TTL 60s (긴 토론) | `chat:thread:*` topic 에 자동 적용 |
| 명시 동의 필수 | `@user` 멘션 포함 시 silent OK 비활성 |
| 다수결 (3+ 세션 토론) | 본 spec 범위 밖. v2 검토 |



## §11. 사용자 인터페이스 (관전 + 인터럽트)

### 11.1 주력 — Web UI

| 동작 | 인터페이스 |
|------|----------|
| 관전 (default) | `http://localhost:7390/` — 4 분할 자동 갱신 |
| 발화 | 입력창 클릭 → `@` → 세션 선택 → 메시지 + Enter |
| 채널 전환 | 각 분할 헤더 클릭 시 다른 채널 swap (옵션, v1 에선 고정 4채널) |
| 알림 | 본인 멘션 (`@user`) 시 빨간 배경 + tab title 깜빡임 + 알림음 (옵션) |
| 검색 | (v2) `Ctrl+F` thread 검색 |

### 11.2 보조 — CLI

```bash
# 관전 (특정 채널 tail)
python tools/chat_server/cli.py watch                # 모든 채널
python tools/chat_server/cli.py watch room:design    # 특정 채널

# 발화
python tools/chat_server/cli.py send "rake 는 누적이 맞음" --channel room:design
python tools/chat_server/cli.py send "@S3 잠깐 멈춰" --channel room:blocker

# 조회
python tools/chat_server/cli.py history room:design --last 50
```

**용도**: SSH 세션 / 헤드리스 환경 / 자동화 스크립트. Web UI 가 주력, CLI 는 보조.

### 11.3 사용자 source 인증 (간단)

- chat-server 가 `POST /chat/send` 에서 `source` 헤더 무시하고 항상 `"user"` 로 publish (publisher_id="chat-server" 동반)
- broker ACL 이 `source="user"` 는 publisher_id="chat-server" 만 허용 (§4.1)
- localhost 전제이므로 토큰 인증 불필요

## §12. E2E 시나리오 — 2 세션 회의 → 합의 → 진행

### 12.1 시나리오 — rake 표기 정렬

**전제**: S2 (Lobby) 가 Foundation.md 의 rake 표기를 수정하려 함. S3 (CC) 의 정본과 정합 필요.

```
[T+0s]   S2 worktree 에서 user 가 작업 시작
         → PreToolUse hook: Foundation.md Edit 직전
         → doc_discovery.py 가 Lobby, CC_PRD 영향 감지
         → 자동 발화 (§9.2):
           topic="chat:room:design"
           body="[AUTO] Editing Foundation.md impacts 3 docs: ..."
           mentions=["@S3"]

[T+1s]   브라우저 #design 분할에 메시지 즉시 등장 (50ms push)
         사용자 (관전 중): 흥미롭게 봄

[T+2s]   S2 가 자율 추가 발언:
         body="@S3 rake 표기를 누적으로 가져갈게. Lobby 에서는 hand-by-hand 누적 합계 표시"
         mentions=["@S3"]

[T+15s]  S3 worktree 의 PreToolUse hook 이 mention 감지
         S3 의 다음 발언 차례에 context inject
         → S3 가 자율 reply:
           kind="reply"
           reply_to=<S2 last seq>
           body="CC 는 flat 표시. hand-by-hand 정산은 backend → engine 으로만, 표시는 flat 0.05BB"

[T+16s]  브라우저 #design 에 S3 답변 (들여쓰기 + "re: ..." 표시)

[T+45s]  S2 가 silent OK 30s 룰로 더 묻지 않고 진행 결정:
         kind="decision"
         body="[ASSUMED] rake = Lobby 누적 / CC flat. 분리 표기 진행."

[T+46s]  사용자가 Web UI 에서 #design 입력창 클릭, "@" 입력
         → 드롭다운: @S2, @S3, ...
         → @S2 선택, 메시지: "@S2 누적 OK. 단 CC flat 의 0.05BB 는 BPP 기준값으로 명시"
         → Enter

[T+47s]  brokers publish → S2 hook 이 다음 cycle 에 mention 감지
         S2 가 작업 방향 조정: Foundation.md edit 에 BPP 기준값 명시

[T+90s]  S2 Edit 완료 → commit → PR → release_lock
         topic="stream:S2" event = DONE (chat 아님)
         → LIVE TRACE 분할에 "stream:S2 DONE pr=#196" 표시
```

### 12.2 검증 가능한 결과

| 항목 | 측정 |
|------|------|
| 자동 발화 latency | T+0 cascade 감지 → T+1 브라우저 표시 < 1s |
| S3 응답 latency | T+2 mention → T+15 hook cycle (worktree 작업 중이면 다음 cycle) |
| silent OK 트리거 | T+16 reply 후 T+45 까지 추가 대화 없음 → S2 자율 decision |
| 사용자 인터럽트 | T+46 user 발화 → T+47 S2 hook 감지 → 작업 방향 조정 |
| event 와 분리 | rake decision 은 chat 만, S2 commit/PR 은 event bus |



## §13. broker SPOF + Graceful Degradation

### 13.1 시나리오 매트릭스

| 시나리오 | chat-server 동작 | 브라우저 동작 | 세션 hook 동작 |
|---------|----------------|------------|-------------|
| broker 정상 | SSE push 실시간 | 즉시 표시 | mention inject 정상 |
| broker 죽음 | `subscribe` timeout 30s 마다 재시도 (backoff 1s→5s→30s) | `EventSource` 자동 재연결 | publish 실패 → silent skip + log |
| broker 재시작 | `subscribe(from_seq=<last>)` replay (최대 50건) | 누락 메시지 catch-up | hook 다음 cycle 에 catch-up |
| chat-server 죽음 | `restart: unless-stopped` 자동 재기동 | `EventSource` 5s 재연결 | 영향 없음 (broker 직접 사용) |
| 브라우저 새로고침 | history 50건 catch-up + SSE 재구독 | 페이지 재로딩 | 영향 없음 |

### 13.2 broker 재시작 시 chat-server 복구 흐름

```
broker 죽음 감지 (chat-server subscribe timeout 누적 3회)
       │
       ▼
SSE 클라이언트들에게 "broker disconnected" 시스템 메시지 push
브라우저 UI: 상단 빨간 배너 "broker offline, retrying..."
       │
       ▼ backoff 1s → 5s → 30s (최대)
       │
broker 재기동 감지 (subscribe 성공)
       │
       ▼
subscribe(from_seq=<last_known>) 로 missed events replay
       │
       ▼
SSE 클라이언트들에게 missed events forward
브라우저 UI: 배너 사라짐, missed 메시지 시간순 삽입
```

### 13.3 메시지 손실 가능성

| 케이스 | at-least-once? | 완화 |
|-------|:--------------:|-----|
| broker 정상 | ✓ | events.db WAL 영구 |
| broker kill -9 직후 publish | ✗ (race) | hook idempotent (재시도 시 동일 seq 보장 X — 별도 dedup key 필요) |
| chat-server 재시작 중 publish | ✓ | broker 가 events.db 영구 저장 |
| 브라우저 offline | ✓ | SSE 재연결 + `from_seq` replay |

**원칙**: chat 메시지 손실은 event bus 와 동일 수준의 신뢰성. 단, **합의 결과 (decision kind)** 는 commit/PR 같은 git 산출물에도 별도 기록 권장 (chat 만 의존 금지).

## §14. 위험 + 완화

| ID | 위험 | 발생 시점 | 영향 | 완화 |
|----|------|----------|------|------|
| R1 | broker 죽음 | 어느 때든 | chat 영구 불가 | §13. subscribe backoff + 자동 재기동 |
| R2 | 컨테이너 → host broker 통신 실패 | Linux 환경 | chat-server fail | docker-compose `extra_hosts: host.docker.internal:host-gateway` |
| R3 | 메시지 폭주 (자율 발화 과다) | 다중 cascade 동시 발생 | 가독성 ↓ + broker 부하 | §9.4 rate limit 분당 10건 / 세션 |
| R4 | 사용자 source spoofing | 세션이 `source="user"` 시도 | 사용자 사칭 | §4.1 broker ACL — publisher_id="chat-server" 만 source="user" 발급 가능 |
| R5 | @user 멘션 무한 escalation | 세션 conflict 반복 | 사용자 알림 폭주 | thread_id 단위 escalation 1회 제한 |
| R6 | SSE 끊김 (proxy / WiFi) | 브라우저 환경 | 메시지 누락 표시 | EventSource 자동 재연결 + `from_seq` replay |
| R7 | events.db 무한 성장 | chat 메시지 누적 | 디스크 fill | 14일 retention (store.py 추후 cron) |
| R8 | silent OK 30s 부당 진행 | reply 가 31초에 도착 | 결정 번복 비용 | §10.3 escalation 자동 — 사용자가 최종 판정 |
| R9 | 채널 4개 부족 | 동시 토론 5+ | UI 혼잡 | thread topic (`chat:thread:*`) 으로 분기 |
| R10 | broker `topics.py` 변경이 기존 test 깸 | Phase A 통합 시 | 기존 ACL test fail | 변경 1줄 (prefix 추가) 만 — 기존 test 영향 0 검증 |

### 14.1 R1 (broker SPOF) 상세

broker = 단일 호스트 Python 프로세스. 이미 supervisor (`start_message_bus.py`) 가 PID + heartbeat + port lock 관리. chat-server 추가로 SPOF 증가 X — broker 위에 layer 만 추가.

**Production 강화 시**: broker 자체를 컨테이너화 + replication. 본 spec 범위 밖.

### 14.2 R7 (디스크) 상세

| 메시지 평균 크기 | 일일 메시지 수 | 14일 누적 |
|----------------|--------------|---------|
| ~500 bytes (자유 텍스트) | 500/day (보수적) | ~3.5 MB |
| ~2 KB (긴 토론) | 2000/day (활발) | ~56 MB |

events.db 는 이미 message_bus 가 사용 중. chat 추가로 14일 retention 합쳐도 100 MB 이하. WAL rotate 가 자동 처리.



## §15. Migration Path — 7 Day

| Day | 작업 | 산출물 | 검증 |
|-----|------|--------|------|
| 1 | broker `topics.py` chat:* prefix + `Chat_Protocol.md` schema SSOT | 1 줄 diff + 신규 doc | `pub_demo.py` 로 chat:room:design 자유 발화 동작. 기존 test 100% PASS |
| 2 | `tools/chat_server/server.py` FastAPI (SSE + send + peers + history) | ~220 LOC | curl 로 SSE / POST / GET 동작. broker round-trip < 200ms |
| 2.5 | Dockerfile + docker-compose.yml + requirements.txt | ~50 LOC | `docker compose up -d` 후 `/health` 200 OK |
| 3 | `tools/chat_server/ui/` 4분할 + `app.js` (@ autocomplete) | ~360 LOC | 브라우저에서 4 채널 동시 SSE + @ 드롭다운 동작 |
| 4 | `orch_PreToolUse.py` 자율 발화 트리거 + `orch_SessionStart.py` mention 감지 | ~120 LOC | mock cascade 시 자동 발화 + 다른 worktree 가 mention context 받음 |
| 5 | LIVE TRACE 분할 + reply_to 시각화 | ~80 LOC | event bus mirror 가 4번째 분할에 표시. reply 들여쓰기 |
| 6 | 합의 30s silent OK + 2 세션 E2E (회의 → 합의 → 진행) | tests/e2e/chat_consensus.py | §12 시나리오 100% PASS |
| 7 | 컨테이너 운영 검증 + `Docker_Runtime.md` 섹션 추가 | 운영 doc | broker kill → chat-server backoff → 재기동 → catch-up 검증 |

총 변경:

| 파일 | LOC |
|------|-----|
| `tools/orchestrator/message_bus/topics.py` | +1 |
| `docs/4. Operations/Chat_Protocol.md` (신규) | ~180 |
| `docs/4. Operations/Inter_Session_Chat_Design.md` (본 spec) | (현재) |
| `tools/chat_server/server.py` (신규) | ~220 |
| `tools/chat_server/ui/index.html` (신규) | ~80 |
| `tools/chat_server/ui/app.js` (신규) | ~280 |
| `tools/chat_server/cli.py` (신규) | ~120 |
| `tools/chat_server/Dockerfile` (신규) | ~20 |
| `tools/chat_server/docker-compose.yml` (신규) | ~25 |
| `tools/chat_server/requirements.txt` (신규) | ~5 |
| `.claude/hooks/orch_PreToolUse.py` | +70 |
| `.claude/hooks/orch_SessionStart.py` | +50 |
| `docs/4. Operations/team_assignment_v10_3.yaml` | +20 |
| `docs/4. Operations/Docker_Runtime.md` | +50 |
| `tests/e2e/chat_consensus.py` (신규) | ~150 |

**기존 broker / event bus 코드 변경 1 줄** (topics.py prefix).

## §16. Critical Files

| 카테고리 | 경로 | 상태 |
|---------|------|------|
| 본 spec (이 문서) | `docs/4. Operations/Inter_Session_Chat_Design.md` | ACTIVE (DESIGN) |
| Chat Protocol SSOT | `docs/4. Operations/Chat_Protocol.md` | TBD (Day 1) |
| Backlog | `docs/4. Operations/Conductor_Backlog/B-222-inter-session-chat-ui.md` | PENDING |
| broker (변경 1줄) | `tools/orchestrator/message_bus/topics.py` | EXISTING |
| chat-server | `tools/chat_server/server.py` | TBD (Day 2) |
| Web UI | `tools/chat_server/ui/index.html` + `app.js` | TBD (Day 3) |
| CLI (보조) | `tools/chat_server/cli.py` | TBD (Day 7) |
| Docker | `tools/chat_server/Dockerfile` + `docker-compose.yml` | TBD (Day 2.5) |
| Hooks | `.claude/hooks/orch_PreToolUse.py`, `orch_SessionStart.py` | EXISTING (수정) |
| stream ACL config | `docs/4. Operations/team_assignment_v10_3.yaml` | EXISTING (추가) |
| 운영 doc | `docs/4. Operations/Docker_Runtime.md` | EXISTING (섹션 추가) |
| E2E test | `tests/e2e/chat_consensus.py` | TBD (Day 6) |

## §17. Out of Scope (이번 spec 범위 밖)

| 항목 | 이유 |
|------|-----|
| 강한 인증 (토큰 / OAuth) | localhost dev 전제. production 강화 시 별도 spec |
| broker 컨테이너화 | 호스트 Python + supervisor 가 안정. hook latency 우려 |
| broker replication / HA | SPOF 허용 (dev). graceful degradation 으로 충분 |
| Slack / Discord 연동 | 외부 시스템. 내부 dev 협업으로 한정 |
| 음성 / 화상 | dev 도구 범위 밖 |
| 메시지 검색 (full-text) | v2. 일단 시간순 50건 history 로 충분 |
| 다수결 (3+ 세션 토론) | §10.4 — v2 검토 |
| 사용자가 발화 권한을 가지는 stream (`source="S2"` 사용자 발언 등) | v1 에선 사용자 = `source="user"` 만. 추후 admin override 검토 |
| Conflict-free thread merge | 단일 broker SQLite 이라 conflict 자체가 없음 (직렬화) |
| Production 배포 | dev 보조 도구로 한정. 본 spec 의 모든 결정이 dev 전제 위에 |

## §18. References

| 카테고리 | 경로 |
|---------|------|
| 기반 인프라 | [`Message_Bus_Runbook.md`](./Message_Bus_Runbook.md) |
| 멀티 세션 spec | [`Multi_Session_Design_v11.md`](./Multi_Session_Design_v11.md) |
| Topic ACL 정책 | `tools/orchestrator/message_bus/topics.py` |
| Stream 매트릭스 | [`team_assignment_v10_3.yaml`](./team_assignment_v10_3.yaml) |
| 운영 절차 (Docker) | [`Docker_Runtime.md`](./Docker_Runtime.md) |
| Backlog 항목 | [`B-222-inter-session-chat-ui.md`](./Conductor_Backlog/B-222-inter-session-chat-ui.md) |
| Plan 파일 (다음 단계) | TBD (`writing-plans` skill 출력) |
| Confluence (parent) | https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3811573898 |

---

## Edit History

| 날짜 | 버전 | 트리거 | 변경 |
|------|:----:|--------|------|
| 2026-05-11 | v1.0.0 | 사용자 directive — "각 멀티 세션이 서로 의사소통하는 채팅창" + Docker container + 4분할 Web UI + @ 멘션 인터랙티브 | 최초 작성 (B-222) |

