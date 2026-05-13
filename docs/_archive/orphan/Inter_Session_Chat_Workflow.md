---
title: Inter-Session Chat Workflow — 멀티 세션 발화/응답 룰
owner: conductor
tier: internal
status: ACTIVE
spec: docs/4. Operations/Inter_Session_Chat_Design.md
mcp-config: .mcp.json (ebs-message-bus entry)
last-updated: 2026-05-12
---

# Inter-Session Chat Workflow

> **목적**: B-222 채팅 인프라 (broker + Web UI + hooks) 위에서 멀티 세션이 자율적으로 회의/협의하는 룰 spec.
>
> **위치**: Inter_Session_Chat_Design.md 가 *인프라 spec* / 본 문서가 *사용 룰 spec*.

## §1. 발화 트리거 매트릭스

모든 stream (S1~S11, SMEM) 가 따라야 하는 발화 룰:

| 상황 | trigger | 채널 | 발화 주체 |
|------|---------|------|---------|
| `.md` cascade 감지 | PreToolUse hook | `chat:room:design` | Hook (자동, `emit_chat_advisory`) |
| 외부 의존 BLOCKED | team_session_start dep check | `chat:room:blocker` | Hook (자동) |
| scope 위반 시도 | PreToolUse scope check | `chat:room:handoff` | Hook (자동) |
| 사용자 결정 필요 | Claude 자율 판단 | 어느 chat:* + `@user` | Claude (MCP tool) |
| 세션 협의 자발 | Claude 자율 판단 | `chat:room:design` 등 | Claude (MCP tool) |
| status (DONE/BLOCKED) | team_session_end | `stream:S{N}` (chat 아님) | Hook (자동) |

### 두 종류 신호 분리

| 종류 | 매체 | 의미 |
|------|-----|------|
| **사람·세션 토론** | `chat:room:*` | 의문 해소 / 합의 / 인계 — 사람 개입 가능 |
| **기계 상태** | `stream:*` / `cascade:*` / `pipeline:*` | DONE / BLOCKED / 영향 — 자동 react, 사람 개입 X |

## §2. Claude 의 발화 권한 (MCP)

각 stream worktree 의 `.mcp.json` 에 broker 등록 — `tools/orchestrator/setup_stream_worktree.py` 의 Step 7 이 자동 생성 (per-stream, gitignored):

```json
{
  "mcpServers": {
    "ebs-message-bus": {
      "type": "http",
      "url": "http://127.0.0.1:7383/mcp"
    }
  }
}
```

이로써 Claude 가 **다음 도구 직접 호출** 가능:

| MCP tool | 사용 |
|---------|------|
| `mcp__ebs-message-bus__publish_event` | 채팅 발화 |
| `mcp__ebs-message-bus__subscribe` | 새 메시지 long-poll (필요 시) |
| `mcp__ebs-message-bus__get_history` | 채널 history 조회 |
| `mcp__ebs-message-bus__discover_peers` | 활성 stream 목록 |
| `mcp__ebs-message-bus__acquire_lock` | cascade race 방지 |

### 발화 예시 (Claude 가 직접 호출)

```
S2 Claude 작업 중 — "@S3 에게 rake 정합성 물어봐야 한다" 판단

→ mcp__ebs-message-bus__publish_event(
    topic="chat:room:design",
    payload={
      "kind": "msg",
      "from": "S2",
      "to": ["S3"],
      "body": "@S3 rake 표기 누적 vs flat?",
      "mentions": ["@S3"],
      "reply_to": null,
      "thread_id": null,
      "ts": "2026-05-12T..."
    },
    source="S2"
  )
```

### 자율 발화 트리거 (Claude 가 자체 판단)

| 상황 | 발화 행동 |
|------|----------|
| 다른 stream 의 정본 영역 영향 의심 | `chat:room:design` + `@owner` mention |
| 외부 의존으로 BLOCKED | `chat:room:blocker` + `@책임 stream` mention |
| 작업 인계 결정 | `chat:room:handoff` + `@대상 stream` mention |
| 사용자 판단 필요 | 어느 chat 채널 + `@user` mention |
| 합의 종결 (silent_ok 30s 후) | 동일 채널 + `kind=decision` + `reply_to=원본` |

## §3. 응답 의무 (CRITICAL)

각 stream Claude 는 mention 받았을 때 **다음 발언 차례에 응답 필수**.

### 메커니즘

```
1. 다른 세션 / user 가 @S2 mention publish
   ↓
2. S2 worktree 의 SessionStart hook (다음 cycle)
   - inject_chat_mentions(team_id="S2") 가 chat:* 의 새 mention 감지
   - 발견 시 stderr 에 "[CHAT MENTIONS]" 출력
   - S2 Claude 의 context 에 inject 됨
   ↓
3. S2 Claude — 다음 발언 차례에:
   - mcp__ebs-message-bus__publish_event 로 reply publish
   - reply_to = 원본 seq, mentions = ["@<발신자>"]
   ↓
4. 응답 X = 30s 후 발신자가 silent_ok decision 자동 publish (불완전 합의 위험)
```

### 응답 형식

```
mcp__ebs-message-bus__publish_event(
  topic="chat:room:design",   # 원본 채널과 동일
  payload={
    "kind": "reply",
    "from": "S2",
    "to": ["<발신자>"],
    "body": "<답변 본문>",
    "mentions": ["@<발신자>"],
    "reply_to": <원본 seq>,   # 핵심 — 스레드 연결
    "thread_id": null,
    "ts": "..."
  },
  source="S2"
)
```

### 응답 못 함 / 미루기

- 즉시 답 불가능: `kind=msg` + `body="@<발신자> N분 후 답변 예정 (이유)"` publish
- 사용자 결정 필요: `kind=msg` + `@user` mention 추가 publish

## §4. 합의 모델 (silent_ok 30s)

질문 publish 후 30초 응답 없음 → 발화자가 자율 진행 선언 (`kind=decision`).

### 자동 트리거 — 자기 발화 후 30s 자가 확인

```python
# 발화자 Claude 의 자율 로직:
# 1. mcp__ebs-message-bus__publish_event (질문)
# 2. (다른 작업 진행, 30s 경과)
# 3. SessionStart hook 또는 자율 cycle 에서:
#    mcp__ebs-message-bus__get_history(topic, since_seq=question_seq, limit=20)
#    replies = [e for e in events if e.payload.reply_to == question_seq]
# 4. replies 없음 + 30s 경과 + @user 미멘션 → silent_ok decision publish
```

### @user 멘션 포함 시

- silent_ok **비활성** (사용자 명시 답변 대기)
- 사용자가 Web UI 에서 직접 응답할 때까지 무한 대기

### Escalation (응답 충돌)

```
S2: "rake 누적" decision publish (silent_ok 후)
   ↓ 30초 후
S3: 늦게 응답 — "@S2 잠깐, flat 이어야 함" (kind=msg, reply_to=원본)
   ↓
S2 가 자기 decision 이후 반대 의견 감지
   ↓
S2 자동 escalation: chat:room:blocker 로 thread 이전 + @user 멘션
   "[BLOCKED] decision (seq=N) contradicts S3 reply (seq=M). @user 결정 필요."
```

## §5. 사용자 인터럽트

사용자가 세션과 통신하는 3 가지 경로:

| 경로 | 명령 | 효과 |
|------|------|------|
| Web UI 입력창 | `@S2 잠깐` + Enter | 해당 채널 publish → S2 SessionStart hook 감지 |
| CLI send | `python -m tools.chat_server.cli send --channel room:design "@S2 ..."` | 동일 |
| Web UI `@user` 응답 | 다른 세션의 `@user` mention 에 직접 답 | 해당 세션 SessionStart 가 mention 감지 |

## §6. 채널 컨벤션 (v1 default 3개)

| 채널 | 용도 | 발화 빈도 |
|------|-----|---------|
| `chat:room:design` | PRD/정본/설계 협의 (가장 많이 사용) | 높음 |
| `chat:room:blocker` | 외부 의존 / 차단 신호 | 중간 |
| `chat:room:handoff` | stream 간 작업 인계 | 낮음 |

추가 패턴 (필요 시):
- `chat:dm:<A>-<B>` — 1:1 대화
- `chat:thread:<id>` — 긴 토론 격리
- `chat:room:<name>` — 임의 새 채널

## §7. 메시지 종류 (kind)

| kind | 사용 |
|------|------|
| `msg` | 일반 발언 / 질문 |
| `reply` | `reply_to` 가 있는 답변 |
| `system` | Hook 자동 (`emit_chat_advisory` 등) |
| `decision` | 합의 종결 (`[ASSUMED] proceeding...`) |

## §8. 빠른 체크리스트 (각 stream Claude 가 cycle 마다)

```
[ ] SessionStart hook 의 [CHAT MENTIONS] 출력 확인
[ ] 받은 mention 있으면 → 다음 발언 차례에 reply publish
[ ] 작업 중 cascade 감지 → PreToolUse hook 자동 처리 (수동 X)
[ ] 외부 의존 BLOCKED → chat:room:blocker + @책임 stream
[ ] scope 위반 시도 감지 → chat:room:handoff + @owner stream
[ ] 사용자 결정 필요 → @user mention 명시
[ ] 자기 질문 30s+ 응답 없음 → silent_ok decision publish
```

## §9. References

- 인프라 spec: [`Inter_Session_Chat_Design.md`](./Inter_Session_Chat_Design.md)
- broker 운영: [`Message_Bus_Runbook.md`](./Message_Bus_Runbook.md)
- 멀티 세션 spec: [`Multi_Session_Design_v11.md`](./Multi_Session_Design_v11.md)
- protocol SSOT: [`Chat_Protocol.md`](./Chat_Protocol.md)
- 사용자 수동 검증: [`Inter_Session_Chat_Manual_Verification.md`](./Inter_Session_Chat_Manual_Verification.md)
- MCP config: `.mcp.json` (repo root)
- hook impl: `.claude/hooks/orch_PreToolUse.py` + `.claude/hooks/orch_SessionStart.py`
- helper: `tools/chat_server/hook_integration.py`
