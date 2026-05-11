---
title: NOTIFY-team3 — B-331 /engine/health 코드 구현 필요 (S8 scope 외)
owner: conductor (audit trail)
target: stream:team3 (team3-engine 코드)
tier: notify
status: OPEN
related-backlog: B-331
last-updated: 2026-05-11
---

# NOTIFY-team3 — B-331 `/engine/health` 코드 구현 필요

## 트리거

2026-05-11 S8 자율 P0 사이클 (B-330 → B-332 → B-331 분석) 중 B-331 의 코드 변경 영역이 S8 scope_owns (`docs/2. Development/2.3 Game Engine/**`) 밖임을 확인.

## 현황

| 영역 | 상태 | 위치 |
|------|:----:|------|
| **문서** (Harness §2.13 + §1 등재) | ✅ DONE (B-331 1차) | `APIs/Harness_REST_API.md` 이미 §2.13 + §1#13 등재 (2026-04-22 commit) |
| **코드 구현** | ⏳ 미진행 | `team3-engine/ebs_game_engine/lib/harness/server.dart` — `HarnessServer._handleRequest` 에 `GET /engine/health` 라우트 추가 필요 |
| **응답 JSON 스키마** | 📋 spec 확정 | B-331 backlog 본문 명시 (status / version / uptime_seconds / sessions_active / timestamp) |
| **수락 기준 (curl)** | ⏳ 코드 구현 후 검증 | `curl -s http://localhost:8080/engine/health` 200 OK |

## 처리 요청 (team3 worktree)

team3 (또는 team3-engine 소유 stream) 에서:

1. `team3-engine/ebs_game_engine/lib/harness/server.dart` `_handleRequest` 분기 추가
2. 응답 JSON 빌더 (status="ok" 고정, version=pubspec 추출, uptime=Process start delta, sessions_active=`_sessions.length`)
3. PR title: `feat(team3-engine): B-331 /engine/health endpoint 구현`
4. 머지 후 본 NOTIFY 파일 → status: CLOSED 또는 archive 이동

## scope 분리 사유

- S8 stream 의 `scope_owns` = `docs/2. Development/2.3 Game Engine/**` 만
- team3-engine 코드는 `team3` stream 또는 별도 dispatch 필요
- 문서/코드 atomic PR 원칙 — 한 PR 에 같은 backlog 의 문서+코드 분산은 review 부담 증가

## 의존성

- team4 `engine_connection_provider` 의 Demo Mode 3-stage probe 구현이 본 코드 구현을 기다림
- Foundation §B.3 (=구 §6.3) Demo Mode fallback 완성 조건

## 참조

- B-331 backlog: `Backlog/B-331-harness-engine-health-endpoint.md`
- Harness 문서 정본: `APIs/Harness_REST_API.md` §1#13 + §2.13
- Foundation §B.3 (통신 매트릭스 — Engine REST stateless)
