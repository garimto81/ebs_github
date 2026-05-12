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
