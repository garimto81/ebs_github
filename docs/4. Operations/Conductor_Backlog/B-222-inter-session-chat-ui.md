---
id: B-222
title: "B-222 — Inter-Session Chat UI (4분할 Web UI + @ 멘션, Docker container)"
owner: conductor
tier: internal
status: PENDING
type: backlog
severity: MEDIUM
blocker: false
source: docs/4. Operations/Inter_Session_Chat_Design.md
related-issue: TBD
last-updated: 2026-05-11
---

## 배경

기존 `message_bus` (broker @ 7383) 는 **이벤트 알림판** 으로 설계 (publish/subscribe + strict ACL, structured JSON payload). 사용자가 원했던 멘탈 모델은 **세션 간 채팅방** — 자유 텍스트 대화 + 스레드 + @ 멘션 + 사람 관전. 두 모델은 데이터 구조 자체가 다름 (event = "일이 일어났다" vs chat = "내가 너에게 말한다").

## 결정 — 어댑터 방식 (broker 보존)

기존 broker 인프라 (SQLite WAL + 7 MCP tools + supervisor + 4 Phase 검증) **그대로 유지**. 새 `chat:{room}` topic 네임스페이스 위에 채팅 의미론 (자유 텍스트, 멘션, 답장, 합의 모델) 을 얹고, FastAPI chat-server 컨테이너가 broker ↔ 브라우저 SSE 중계.

## 작업 범위 (예상 7 Day)

| Day | 산출물 |
|-----|--------|
| 1 | `topics.py` chat:* prefix 추가 + `Chat_Protocol.md` schema SSOT |
| 2 | `tools/chat_server/server.py` FastAPI (SSE + send + peers + history) |
| 2.5 | Dockerfile + docker-compose.yml + requirements.txt |
| 3 | `tools/chat_server/ui/` 4분할 정적 HTML + `app.js` (@ autocomplete) |
| 4 | `orch_PreToolUse.py` 자율 발화 트리거 + `orch_SessionStart.py` mention 감지 |
| 5 | LIVE TRACE 분할 (event bus mirror) + reply_to 시각화 |
| 6 | 합의 30s silent OK 룰 + 2 세션 E2E (회의 → 합의 → 진행) |
| 7 | 컨테이너 운영 검증 + `Docker_Runtime.md` 섹션 추가 (S11 협의) |

## 수락 기준

| 항목 | 기준 |
|------|------|
| 4분할 Web UI | `http://localhost:7390/` 진입 시 4 채널 (#design, #blocker, #handoff, LIVE TRACE) 동시 표시 |
| 실시간 push | SSE 로 broker publish → 브라우저 표시 latency p99 < 500ms |
| @ 멘션 | `@` 입력 시 active 세션 드롭다운 (discover_peers 결과) + 화살표 + Enter 자동완성 |
| 사용자 발화 | `POST /chat/send` 로 broker publish (source="user") |
| 세션 자율 응답 | @ 멘션 받은 세션이 다음 hook cycle 에 reply publish |
| Docker 컨테이너 | `docker compose -f tools/chat_server/docker-compose.yml up -d` 단일 명령 기동 |
| broker SPOF | broker 죽어도 chat-server 는 SSE 재구독 backoff (1s → 5s → 30s) |
| 기존 broker 코드 | 변경 0 줄 (`topics.py` 1줄 prefix 추가만 예외) |

## 관련 spec / 코드

| 카테고리 | 경로 |
|---------|------|
| **본 spec** | `docs/4. Operations/Inter_Session_Chat_Design.md` |
| broker | `tools/orchestrator/message_bus/` (변경 0) |
| 신규 chat-server | `tools/chat_server/` (신규 폴더) |
| hooks | `.claude/hooks/orch_PreToolUse.py`, `orch_SessionStart.py` |
| Topic ACL | `tools/orchestrator/message_bus/topics.py` (1줄 변경) |
| 운영 통합 | `docs/4. Operations/Docker_Runtime.md` (섹션 추가) |
| stream config | `docs/4. Operations/team_assignment_v10_3.yaml` (topics.acl chat:* 등록) |

## 위험

| 위험 | 완화 |
|------|------|
| broker SPOF | chat-server 가 backoff 재구독 + 브라우저 EventSource 자동 재연결 |
| 컨테이너 → host broker 통신 | `host.docker.internal` (Win 자동, Linux 는 extra_hosts host-gateway) |
| 메시지 폭주 (자율 발화 과다) | hook level rate limit (세션당 분당 N 회) + 합의 30s 룰로 thread 종결 |
| 사용자 source spoofing | `chat:room:user` 채널은 별도 ACL — Web UI 만 publish 가능 (header token 단순 검증) |
| SSE 끊김 | 재연결 시 `from_seq=<last>` 으로 missed event replay |

## 다음 단계

본 Backlog 항목 등록 후 → `Inter_Session_Chat_Design.md` spec doc 작성 → 7-Day implementation plan (writing-plans skill) → 실행.
